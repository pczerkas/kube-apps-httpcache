package watcher

import (
	"crypto/md5"
	"encoding/hex"
	"encoding/json"
	"html/template"
	"io"

	"github.com/golang/glog"
	"github.com/pczerkas/kube-apps-httpcache/pkg/env"
)

type Application struct {
	Label       string
	Namespace   string
	Service     string
	PortName    string
	HostRe      string
	VclTemplate string

	BackendUpdates chan *EndpointConfig
	Backend        *EndpointConfig

	vclTemplate *template.Template
	// md5 hash of unparsed template
	vclTemplateHash string
}

type ApplicationList []Application

func applicationListFromJSON(content []byte) (ApplicationList, error) {
	var applications ApplicationList

	err := json.Unmarshal(content, &applications)
	if err != nil {
		return nil, err
	}

	for i := range applications {
		application := &applications[i]
		err := application.setTemplate()
		if err != nil {
			return nil, err
		}
	}

	return applications, nil
}

func (v *Application) setTemplate() error {
	parsedTemplate, err := template.New("vcl").Parse(v.VclTemplate)
	if err != nil {
		return err
	}

	v.vclTemplate = parsedTemplate
	hash := md5.Sum([]byte(v.VclTemplate))
	hashStr := hex.EncodeToString(hash[:])
	v.vclTemplateHash = hashStr

	return nil
}

func (v *Application) RenderVCL(
	target io.Writer,
) error {
	backend := v.Backend

	glog.V(6).Infof(
		"rendering VCL (source md5sum: %s, Application:%v, Backends:%v)",
		v.vclTemplateHash,
		v,
		backend.Endpoints,
	)

	err := v.vclTemplate.Execute(target, &ApplicationTemplateData{
		Application: v,
		Backends:    backend.Endpoints,
		Env:         env.GetEnvironment(),
	})

	return err
}
