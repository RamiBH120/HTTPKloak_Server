package main

import (
    "context"
    "encoding/json"
    "fmt"
    "io"
    "log"
    "net/http"

    "github.com/sardanioss/httpcloak/client"
)

type FetchRequest struct {
    URL     string            `json:"url"`
    Proxy   string            `json:"proxy,omitempty"`
    Headers map[string]string `json:"headers,omitempty"`
}

func main() {
    http.HandleFunc("/fetch", func(w http.ResponseWriter, r *http.Request) {
        var req FetchRequest
        json.NewDecoder(r.Body).Decode(&req)

        c := client.NewClient("chrome-143")
        defer c.Close()

        proxyURL := ""
        if req.Proxy != "" {
            proxyURL = req.Proxy
        }

        resp, err := c.Get(context.Background(), req.URL, client.PreparedRequest{
            Headers: req.Headers,
        })
        if err != nil {
            http.Error(w, err.Error(), 500)
            return
        }
        defer resp.Body.Close()

        body, _ := io.ReadAll(resp.Body)
        w.Header().Set("Content-Type", resp.Header.Get("Content-Type"))
        w.Write(body)
    })

    http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
        w.Write([]byte(`{"status":"ok"}`))
    })

    log.Println("🚀 httpcloak-server on :7878")
    log.Fatal(http.ListenAndServe(":7878", nil))
}
