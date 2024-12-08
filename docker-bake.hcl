target "default" {
  context = "."
  dockerfile = "Dockerfile"
  annotations = ["org.opencontainers.image.description=Wx chapter opener"]
  tags = ["ghcr.io/rdartus/git-sync:latest"]
  platforms = ["linux/amd64", "linux/arm64"]
  output = ["type=registry"]
}
