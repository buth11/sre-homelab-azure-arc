# Linkerd Service Mesh — Part 10

## Instalacja
- Linkerd edge-26.6.1 zainstalowany
- linkerd viz extension zainstalowana
- Namespace default annotowany: linkerd.io/inject=enabled

## Weryfikacja
- aras-demo deployment: MESHED 2/2 (sidecar proxy injected)
- Każdy pod ma 2 kontenery: aplikacja + linkerd-proxy
- mTLS aktywne między wszystkimi meshed podami

## Komendy weryfikacyjne
kubectl get pods -n default | grep aras
# aras-demo-xxx   2/2   Running  <- 2/2 oznacza linkerd sidecar

linkerd viz stat deployment/aras-demo -n default
# MESHED: 2/2

linkerd check
# wszystkie checks zielone
