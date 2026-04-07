FROM golang:1.26-alpine AS builder

RUN apk add --no-cache git

WORKDIR /app

COPY . .

RUN go mod init devops/prova || true
RUN go mod tidy

RUN CGO_ENABLED=0 GOOS=linux go build -o /myapp main.go

FROM alpine:latest

RUN apk --no-cache add ca-certificates

RUN apk update && apk upgrade --no-cache

WORKDIR /root/

COPY --from=builder /myapp .

EXPOSE 8080

# Rodar como usuário não-root por segurança
USER 65534

CMD ["./myapp"]
