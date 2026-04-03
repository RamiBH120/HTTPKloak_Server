package main

import (
    "context"
    "encoding/json"
    "io"
    "log"
    "net/http"

    "github.com/sardanioss/httpcloak/client"
)

type FetchRequest struct {
    URL     string            json:"url"
    Proxy   string            json:"proxy,omitempty"
    Headers map[string]string json:"headers,omitempty"
}

type FetchResponse struct {
    Status  int               json:"status"
    Body    string            json:"body"
    Headers map[string]string json:"headers,omitempty"
}

func main() {
    http.HandleFunc("/fetch", func(w http.ResponseWriter, r http.Request) {
        var req FetchRequest
        if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
            http.Error(w, "invalid JSON body", 400)
            return
        }
        if req.URL == "" {
            http.Error(w, "url is required", 400)
            return
        }

        opts := []client.Option{}
        if req.Proxy != "" {
            opts = append(opts, client.WithProxy(req.Proxy))
        }

        c := client.NewClient("chrome-143", opts...)
        defer c.Close()

        var headers map[string][]string
        if len(req.Headers) > 0 {
            headers = make(map[string][]string, len(req.Headers))
            for k, v := range req.Headers {
                headers[k] = []string{v}
            }
        }

        resp, err := c.Get(context.Background(), req.URL, headers)
        if err != nil {
            http.Error(w, err.Error(), 500)
            return
        }
        defer resp.Body.Close()

        body, err := io.ReadAll(resp.Body)
        if err != nil {
            http.Error(w, err.Error(), 500)
            return
        }

        flatHeaders := make(map[string]string)
        for k, vals := range resp.Headers {
            if len(vals) > 0 {
                flatHeaders[k] = vals[0]
            }
        }

        w.Header().Set("Content-Type", "application/json")
        json.NewEncoder(w).Encode(FetchResponse{
            Status:  resp.StatusCode,
            Body:    string(body),
            Headers: flatHeaders,
        })
    })

    http.HandleFunc("/health", func(w http.ResponseWriter, rhttp.Request) {
        w.Header().Set("Content-Type", "application/json")
        w.Write([]byte({"status":"ok"}))
    })

    log.Println("🚀 httpcloak-server on :7878")
    log.Fatal(http.ListenAndServe(":7878", nil))
}
