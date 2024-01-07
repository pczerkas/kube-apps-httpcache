package controller

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"strings"

	"github.com/golang/glog"
	"github.com/pczerkas/kube-apps-httpcache/pkg/watcher"
)

func (v *VarnishController) Run(ctx context.Context) error {
	glog.Infof("waiting for initial configuration before starting Varnish")

	v.frontend = watcher.NewEndpointConfig()
	if v.frontendUpdates != nil {
		v.frontend = <-v.frontendUpdates
		if v.varnishSignaller != nil {
			v.varnishSignaller.SetEndpoints(v.frontend)
		}
	}

	v.applications = watcher.NewApplicationConfig()
	if v.applicationsUpdates != nil {
		v.applications = <-v.applicationsUpdates
	}

	target, err := os.Create(v.configFile)
	if err != nil {
		return err
	}

	glog.Infof("creating initial VCL config")
	err = v.renderVCL(
		target,
		v.frontend.Endpoints,
		v.frontend.Primary,
		v.applications.Applications,
	)
	if err != nil {
		return err
	}

	_, errChan := v.startVarnish(ctx)

	if err := v.waitForAdminPort(ctx); err != nil {
		return err
	}

	watchErrors := make(chan error)
	go v.watchConfigUpdates(ctx, watchErrors)

	go func(errors chan<- error) {
		err := v.OnApplicationsUpdate(ctx)
		if err != nil {
			errors <- err
			return
		}

		errors <- v.rebuildConfig(ctx)
	}(watchErrors)

	go func() {
		for err := range watchErrors {
			if err != nil {
				glog.Warningf("error while watching for updates: %s", err.Error())
			}
		}
	}()

	return <-errChan
}

func (v *VarnishController) startVarnish(ctx context.Context) (*exec.Cmd, <-chan error) {
	c := exec.CommandContext(
		ctx,
		"varnishd",
		v.generateArgs()...,
	)

	c.Dir = "/"
	c.Stdout = os.Stdout
	c.Stderr = os.Stderr

	r := make(chan error)

	go func() {
		err := c.Run()
		r <- err
	}()

	return c, r
}

func (v *VarnishController) generateArgs() []string {
	args := []string{
		"-F",
		"-f", v.configFile,
		"-S", v.SecretFile,
		"-s", fmt.Sprintf("Cache=%s", v.Storage),
		"-s", fmt.Sprintf("Transient=%s", v.TransientStorage),
		"-a", fmt.Sprintf("%s:%d", v.FrontendAddr, v.FrontendPort),
		"-T", fmt.Sprintf("%s:%d", v.AdminAddr, v.AdminPort),
	}

	if v.AdditionalParameters != "" {
		for _, val := range strings.Split(v.AdditionalParameters, ",") {
			args = append(args, "-p")
			args = append(args, val)
		}
	}

	if v.WorkingDir != "" {
		args = append(args, "-n", v.WorkingDir)
	}

	return args
}
