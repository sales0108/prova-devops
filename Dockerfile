FROM golang:1.21

WORKDIR /app

COPY . .

RUN go mod init devops/prova || true
RUN go mod tidy

RUN go build -o myapp main.go

EXPOSE 8080

CMD ["./myapp"]
