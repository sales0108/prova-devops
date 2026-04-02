package main

import (
	"fmt"
	"log"
	"net/http"
	"time"
)

func main() {
	fmt.Println("Aplicação iniciando... Aguardando 10 segundos de aquecimento.")
	time.Sleep(10 * time.Second)
	fmt.Println("Aplicação pronta e rodando na porta 8080.")

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "Olá, DevOps! Eu sou uma API em Go rodando no EKS.")
	})

	http.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("OK"))
	})

	log.Fatal(http.ListenAndServe(":8080", nil))
}
