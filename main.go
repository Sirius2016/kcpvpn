package main

import (
	"log"
	"os"
	"time"
)

func main() {
	usageFatal := func() {
		log.Fatalf("Usage: %s server|client --help", os.Args[0])
	}

	if len(os.Args) < 2 {
		usageFatal()
	}

	command := os.Args[1]

	StartLogRoutine()
	if command == "server" || command == "s" {
		err := createServerConfig(func(serverConfig *ServerConfig) {
			err := startServer(serverConfig)
			errorCheck(err)
		})
		errorCheck(err)
	} else if command == "client" || command == "c" {
		err := createClientConfig(func(clientConfig *ClientConfig) {
			for {
				err := startClient(clientConfig)
				if err != nil {
					log.Println(err)
				}
				if clientConfig.AutoReconnect == false {
					break
				}
				time.Sleep(3 * time.Second)
			}
		})
		errorCheck(err)
	} else {
		usageFatal()
	}
}

func errorCheck(err error) {
	if err != nil {
		log.Fatal(err)
	}
}