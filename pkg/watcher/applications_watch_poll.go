package watcher

import (
	"crypto/md5"
	"encoding/hex"
	"os"
	"time"

	"github.com/golang/glog"
)

const (
	// how often to check for template file changes
	APPLICATIONS_POLL_INTERVAL = 5 * time.Second
	// how often print template info for troubleshooting
	APPLICATIONS_TIMESTAMP_DISPLAY_INTERVAL = 1 * time.Hour
)

func (t *pollingApplicationsWatcher) Run() (chan *ApplicationConfig, chan error) {
	updates := make(chan *ApplicationConfig)
	errors := make(chan error)

	go t.watch(updates, errors)

	return updates, errors
}

func (t *pollingApplicationsWatcher) watch(updates chan *ApplicationConfig, errors chan error) {
	_, err := os.Stat(t.filename)
	if err != nil {
		errors <- err
	}

	t.lastObservedTimestamp = time.Time{}
	glog.V(6).Infof("observed modification time on %s (%s)", t.filename, t.lastObservedTimestamp.String())

	var i uint64 = 0
	logApplicationsInfoCount := uint64(APPLICATIONS_TIMESTAMP_DISPLAY_INTERVAL / APPLICATIONS_POLL_INTERVAL)
	for {
		stat, err := os.Stat(t.filename)
		if err != nil {
			errors <- err
			time.Sleep(APPLICATIONS_POLL_INTERVAL)
			continue
		}

		modtime := stat.ModTime()
		i++
		if glog.V(6) && (i%logApplicationsInfoCount == 0) {
			logApplicationsInfo(t.filename, modtime, errors)
		}

		if modtime != t.lastObservedTimestamp {
			glog.V(6).Infof("observed new modification time on %s (%s)", t.filename, modtime.String())

			t.lastObservedTimestamp = modtime

			content, err := os.ReadFile(t.filename)
			if err != nil {
				glog.Warningf("error while reading file %s: %s", t.filename, err.Error())

				errors <- err
				continue
			}

			newConfig := NewApplicationConfig()

			newApplicationsList, err := applicationListFromJSON(content)
			if err != nil {
				glog.Errorf("error while building application list: %s", err.Error())
				continue
			}

			newConfig.Applications = newApplicationsList

			updates <- newConfig
		}
		time.Sleep(APPLICATIONS_POLL_INTERVAL)
	}
}

// print template info to assist troubleshooting
func logApplicationsInfo(filename string, modtime time.Time, errors chan error) {
	content, err := os.ReadFile(filename)
	if err != nil {
		glog.Warningf("error while reading file %s: %s", filename, err.Error())
		errors <- err
		return
	}

	hash := md5.Sum(content)
	hashStr := hex.EncodeToString(hash[:])
	glog.Infof("current applications modification time: %s, md5sum: %s", modtime.String(), hashStr)
}
