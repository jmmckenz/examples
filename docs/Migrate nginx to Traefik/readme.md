
# WORK IN PROGRESS....NOT USABLE AT THE MOMENT
# nginx migration tool installation
```
curl -sSL https://raw.githubusercontent.com/traefik/ingress-nginx-migration/main/scripts/install.sh | bash -s -- --no-sudo
```


# Remove unsupported annotations if necessary from Ingress definitions.





# Install Traefik
```
helm repo add traefik https://traefik.github.io/charts
helm repo update
helm upgrade --install traefik traefik/traefik --namespace traefik \
  --create-namespace \
  --set="logs.general.level=DEBUG" \
  --set="service.type=ClusterIP" \
  --set="additionalArguments={--providers.kubernetesIngressNGINX}"
```





  