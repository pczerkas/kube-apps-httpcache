package controller

import (
	"bytes"
	"context"
	"crypto/md5"
	"encoding/hex"
	"fmt"
	"os"
	"sort"
	"strconv"
	"strings"
	"text/template"
	"time"

	"github.com/golang/glog"
	varnishclient "github.com/martin-helmich/go-varnish-client"
	"github.com/pczerkas/kube-apps-httpcache/pkg/watcher"
)

func (v *VarnishController) watchConfigUpdates(
	ctx context.Context,
	errors chan<- error,
) {
	for {
		select {
		case tmplContents := <-v.vclTemplateUpdates:
			glog.Infof("VCL template has been updated")

			err := v.setTemplate(tmplContents)
			if err != nil {
				errors <- err
				continue
			}
			errors <- v.rebuildConfig(ctx)

		case newConfig := <-v.frontendUpdates:
			glog.Infof("received new frontend configuration: %+v", newConfig)

			v.frontend = newConfig

			if v.varnishSignaller != nil {
				v.varnishSignaller.SetEndpoints(v.frontend)
			}

			errors <- v.rebuildConfig(ctx)

		case newConfig := <-v.applicationsUpdates:
			glog.Infof("received new applications configuration: %+v", newConfig)

			v.applications = newConfig

			err := v.OnApplicationsUpdate(ctx)
			if err != nil {
				errors <- err
				continue
			}

			errors <- v.rebuildConfig(ctx)

		case <-ctx.Done():
			errors <- ctx.Err()
			return
		}
	}
}

func (v *VarnishController) OnApplicationsUpdate(
	ctx context.Context,
) error {
	if v.backendsCancel != nil {
		(*v.backendsCancel)()
	}
	backendsCtx, backendsCancel := context.WithCancel(context.Background())
	v.backendsCancel = &backendsCancel
	for i := range v.applications.Applications {
		application := &v.applications.Applications[i]
		if application.Label == "" ||
			application.Namespace == "" ||
			application.Service == "" ||
			application.PortName == "" {
			glog.Infof("skipping application as it is not fully defined")
			continue
		}
		var backendUpdates chan *watcher.EndpointConfig
		var backendErrors chan error
		backendWatcher := watcher.NewEndpointWatcher(
			v.client,
			application.Namespace,
			application.Service,
			application.PortName,
			v.retryBackoff,
		)
		backendUpdates, backendErrors = backendWatcher.Run(backendsCtx)
		application.BackendUpdates = backendUpdates

		application.Backend = watcher.NewEndpointConfig()
		if application.BackendUpdates != nil {
			application.Backend = <-application.BackendUpdates
		}

		watchErrors := make(chan error)
		go v.watchBackendUpdates(backendsCtx, application, watchErrors)

		go func() {
			for err := range watchErrors {
				if err.Error() == "context canceled" {
					return
				}
				if err != nil {
					glog.Warningf("error while watching for backend updates: %s", err.Error())
				}
			}
		}()

		go func() {
			for {
				select {
				case err := <-backendErrors:
					glog.Errorf("error while watching backend: %s", err.Error())

				case <-ctx.Done():
					watchErrors <- ctx.Err()
					return

				case <-backendsCtx.Done():
					watchErrors <- backendsCtx.Err()
					return
				}
			}
		}()
	}

	return nil
}

func (v *VarnishController) watchBackendUpdates(
	ctx context.Context,
	application *watcher.Application,
	errors chan<- error,
) {
	for {
		select {
		case newConfig := <-application.BackendUpdates:
			glog.Infof("received new backend configuration: %+v", newConfig)

			application.Backend = newConfig

			errors <- v.rebuildConfig(ctx)

		case <-ctx.Done():
			errors <- ctx.Err()
			return
		}
	}
}

func (v *VarnishController) setTemplate(tmplContents []byte) error {
	parsedTemplate, err := template.New("vcl").Parse(string(tmplContents))
	if err != nil {
		return err
	}

	v.vclTemplate = parsedTemplate
	hash := md5.Sum(tmplContents)
	hashStr := hex.EncodeToString(hash[:])
	v.vclTemplateHash = hashStr

	return nil
}

func (v *VarnishController) rebuildConfig(ctx context.Context) error {
	applicationsVCLs := make(map[string][]byte)
	for i := range v.applications.Applications {
		application := &v.applications.Applications[i]
		if application.Backend == nil {
			glog.V(8).Infof("application '%s' has no backend, skipping it", application)
			continue
		}

		buf := new(bytes.Buffer)

		err := application.RenderVCL(buf)
		if err != nil {
			return err
		}

		vcl := buf.Bytes()
		glog.V(8).Infof("new application VCL: %s", string(vcl))

		applicationsVCLs[application.Label] = vcl
	}

	buf := new(bytes.Buffer)

	err := v.renderVCL(
		buf,
		v.frontend.Endpoints,
		v.frontend.Primary,
		v.applications.Applications,
	)
	if err != nil {
		return err
	}

	vcl := buf.Bytes()
	glog.V(8).Infof("new VCL: %s", string(vcl))

	client, err := varnishclient.DialTCP(ctx, fmt.Sprintf("127.0.0.1:%d", v.AdminPort))
	if err != nil {
		return err
	}

	secret, err := os.ReadFile(v.SecretFile)
	if err != nil {
		return err
	}

	err = client.Authenticate(ctx, secret)
	if err != nil {
		return err
	}

	maxVclParam, err := client.GetParameter(ctx, "max_vcl")
	if err != nil {
		return err
	}

	maxVcl, err := strconv.Atoi(maxVclParam.Value)
	if err != nil {
		return err
	}

	loadedVcl, err := client.ListVCL(ctx)
	if err != nil {
		return err
	}

	availableVcl := make([]varnishclient.VCLConfig, 0)

	for i := range loadedVcl {
		if loadedVcl[i].Status == varnishclient.VCLAvailable {
			availableVcl = append(availableVcl, loadedVcl[i])
		}
	}

	if len(loadedVcl) >= maxVcl {
		// we're abusing the fact that "boot" < "reload"
		sort.Slice(availableVcl, func(i, j int) bool {
			return availableVcl[i].Name < availableVcl[j].Name
		})

		for i := 0; i < len(loadedVcl)-maxVcl+1; i++ {
			glog.V(6).Infof("discarding VCL: %s", availableVcl[i].Name)

			err = client.DiscardVCL(ctx, availableVcl[i].Name)
			if err != nil {
				return err
			}
		}
	}

	for label, vcl := range applicationsVCLs {
		format := label + "_20060102_150405.00000"
		configname := strings.ReplaceAll(time.Now().Format(format), ".", "_")

		glog.V(6).Infof("about to create new application VCL: %s", string(configname))
		err = client.DefineInlineVCL(ctx, configname, vcl, varnishclient.VCLStateAuto)
		if err != nil {
			return err
		}

		err = client.AddLabelToVCL(ctx, label, configname)
		if err != nil {
			return err
		}
	}

	configname := strings.ReplaceAll(time.Now().Format("reload_20060102_150405.00000"), ".", "_")

	glog.V(6).Infof("about to create new VCL: %s", string(configname))
	err = client.DefineInlineVCL(ctx, configname, vcl, varnishclient.VCLStateAuto)
	if err != nil {
		return err
	}

	err = client.UseVCL(ctx, configname)
	if err != nil {
		return err
	}
	glog.V(6).Infof("activated new VCL: %s", string(configname))

	if v.currentVCLName == "" {
		v.currentVCLName = "boot"
	}

	if err := client.SetVCLState(ctx, v.currentVCLName, varnishclient.VCLStateCold); err != nil {
		glog.V(1).Infof("error while changing state of VCL %s: %s", v.currentVCLName, err)
	}
	glog.V(6).Infof("deactivated old VCL: %s", string(v.currentVCLName))

	v.currentVCLName = configname

	return nil
}
