package main

import (
	"fmt"
	"github.com/xtaci/kcp-go"
	"log"
)

func startClient(config *ClientConfig) error {
	config.CommonConfig.PrintSummary()

	block := createBlock(&config.CommonConfig)

	remoteAddr := fmt.Sprintf("%s:%d", config.GetIP(), config.GetPort())
	log.Printf("connecting to %s", remoteAddr)
	session, err := kcp.DialWithOptions(remoteAddr, block, config.GetDatashard(), config.GetParityshard())
	if err != nil {
		return err
	}
	defer session.Close()
	session.SetStreamMode(true)
	session.SetWriteDelay(false)
	session.SetNoDelay(config.GetNodelay(), config.GetInterval(), config.GetResend(), config.GetNoCongestion())
	session.SetMtu(int(config.GetUDPMTU()))
	session.SetWindowSize(config.GetSendWindowSize(), config.GetReceiveWindowSize())
	session.SetACKNoDelay(config.GetAckNodelay())

	server, err := NewVPNServer(session, config, config.IsVNIPersistent())
	if err != nil {
		return err
	}
	defer server.Close()

	_, err = IterateState(server)
	return err
}
