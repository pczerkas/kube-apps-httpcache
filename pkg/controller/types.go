package controller

import (
	"io"
	"os"
	"text/template"
	"time"

	"github.com/golang/glog"
	"github.com/pczerkas/kube-apps-httpcache/pkg/env"
	"github.com/pczerkas/kube-apps-httpcache/pkg/signaller"
	"github.com/pczerkas/kube-apps-httpcache/pkg/watcher"
	"k8s.io/client-go/kubernetes"
)

type TemplateData struct {
	Frontends       watcher.EndpointList
	PrimaryFrontend *watcher.Endpoint
	Applications    watcher.ApplicationList
	Env             map[string]string
}

type VarnishController struct {
	SecretFile           string
	Storage              string
	TransientStorage     string
	AdditionalParameters string
	WorkingDir           string
	FrontendAddr         string
	FrontendPort         int
	AdminAddr            string
	AdminPort            int

	vclTemplate *template.Template
	// md5 hash of unparsed template
	vclTemplateHash    string
	vclTemplateUpdates chan []byte

	frontendUpdates chan *watcher.EndpointConfig
	frontend        *watcher.EndpointConfig

	applicationsUpdates chan *watcher.ApplicationConfig
	applications        *watcher.ApplicationConfig

	varnishSignaller *signaller.Signaller
	configFile       string
	client           kubernetes.Interface
	retryBackoff     time.Duration

	// localAdminAddr string
	currentVCLName string
}

func NewVarnishController(
	secretFile string,
	storage string,
	transientStorage string,
	additionalParameter string,
	workingDir string,
	frontendAddr string,
	frontendPort int,
	adminAddr string,
	adminPort int,
	frontendUpdates chan *watcher.EndpointConfig,
	templateUpdates chan []byte,
	applicationsUpdates chan *watcher.ApplicationConfig,
	varnishSignaller *signaller.Signaller,
	vclTemplateFile string,
	applicationsFile string,
	client kubernetes.Interface,
	retryBackoff time.Duration,
) (*VarnishController, error) {
	vclTemplateContents, err := os.ReadFile(vclTemplateFile)
	if err != nil {
		return nil, err
	}

	v := VarnishController{
		SecretFile:           secretFile,
		Storage:              storage,
		TransientStorage:     transientStorage,
		AdditionalParameters: additionalParameter,
		WorkingDir:           workingDir,
		FrontendAddr:         frontendAddr,
		FrontendPort:         frontendPort,
		AdminAddr:            adminAddr,
		AdminPort:            adminPort,
		vclTemplateUpdates:   templateUpdates,
		frontendUpdates:      frontendUpdates,
		applicationsUpdates:  applicationsUpdates,
		varnishSignaller:     varnishSignaller,
		configFile:           "/tmp/vcl",
		client:               client,
		retryBackoff:         retryBackoff,
	}
	err = v.setTemplate(vclTemplateContents)
	if err != nil {
		return nil, err
	}

	return &v, nil
}

func (v *VarnishController) renderVCL(
	target io.Writer,
	frontendList watcher.EndpointList,
	primaryFrontend *watcher.Endpoint,
	applicationList watcher.ApplicationList,
) error {
	filteredApplicationList := make(watcher.ApplicationList, 0)
	for i := range applicationList {
		application := &applicationList[i]
		if application.Backend == nil {
			glog.V(8).Infof("application '%s' has no backend, skipping it", application)
			continue
		}

		filteredApplicationList = append(filteredApplicationList, *application)
	}

	glog.V(6).Infof(
		"rendering VCL (source md5sum: %s, Frontends:%v, PrimaryFrontend:%v, Applications:%v)",
		v.vclTemplateHash,
		frontendList,
		primaryFrontend,
		filteredApplicationList,
	)

	err := v.vclTemplate.Execute(target, &TemplateData{
		Frontends:       frontendList,
		PrimaryFrontend: primaryFrontend,
		Applications:    filteredApplicationList,
		Env:             env.GetEnvironment(),
	})

	return err
}
