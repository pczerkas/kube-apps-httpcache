package env

import (
	"os"
	"strings"
)

func GetEnvironment() map[string]string {
	items := make(map[string]string)
	for _, e := range os.Environ() {
		pair := strings.SplitN(e, "=", 2)
		items[pair[0]] = pair[1]
	}
	return items
}
