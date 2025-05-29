#!/usr/bin/env bash

APIGEE_URL=""
AUTH=""

set -euo pipefail

# Arrays para almacenar resultados
declare -a environments developers allProxies allProducts
declare -a associatedProducts associatedProxies
declare -a nonAssociatedProducts nonAssociatedProxies

# Arrays asociativos para evitar duplicados
declare -A seenProd seenProxy

timestamp=$(date "+%Y%m%d_%H%M")
printf 'App;Developer;APIProduct;Proxy;KVM;Target\n' > resultado_$timestamp.csv

# 1) Entornos
environmentsJson=$(wget --quiet --no-check-certificate \
    --header="Authorization: Basic $AUTH" \
    -O - "$APIGEE_URL/environments")
environments=()
mapfile -t environments < <(echo "$environmentsJson" | jq -r '.[]')

# 2) Developers
developersJson=$(wget --quiet --no-check-certificate \
    --header="Authorization: Basic $AUTH" \
    -O - "$APIGEE_URL/developers")
developers=()
mapfile -t developers < <(echo "$developersJson" | jq -r '.[]')

# 3) Todos los proxies
allProxiesJson=$(wget --quiet --no-check-certificate \
    --header="Authorization: Basic $AUTH" \
    -O - "$APIGEE_URL/apis")
allProxies=()
mapfile -t allProxies < <(echo "$allProxiesJson" | jq -r '.[]')

# 4) Todos los productos
productList=$(wget --quiet --no-check-certificate \
    --header="Authorization: Basic $AUTH" \
    -O - "$APIGEE_URL/apiproducts")
allProducts=()
mapfile -t allProducts < <(echo "$productList" | jq -r '.[]')

#
# Recolectar productos y proxies asociados a apps de cada developer
#

echo "Recorremos apps"

for dev in "${developers[@]}"; do
    # Apps del developer
    appsDev=$(wget --quiet --no-check-certificate \
        --header="Authorization: Basic $AUTH" \
        -O - "$APIGEE_URL/developers/$dev/apps")
    appsList=()
    mapfile -t appsList < <(echo "$appsDev" | jq -r '.[]')

    for app in "${appsList[@]}"; do
        # Productos de la app
        appDetails=$(wget --quiet --no-check-certificate \
            --header="Authorization: Basic $AUTH" \
            -O - "$APIGEE_URL/developers/$dev/apps/$app")
        products=()
        mapfile -t products < <(
            echo "$appDetails" \
            | jq -r '.credentials[] .apiProducts[] .apiproduct'
        )

        for product in "${products[@]}"; do
            # Si no lo hemos visto antes, lo añadimos
            if [[ -z ${seenProd["$product"]+x} ]]; then
                associatedProducts+=("$product")
                seenProd["$product"]=1
            fi

            # Detalles del producto: para extraer sus proxies
            prodDetails=$(wget --quiet --no-check-certificate \
                --header="Authorization: Basic $AUTH" \
                -O - "$APIGEE_URL/apiproducts/$product")
            proxies=()
            mapfile -t proxies < <(
                echo "$prodDetails" \
                | jq -r '.proxies[]'
            )

            for proxy in "${proxies[@]}"; do
                # Proxy asociado (sin duplicados)
                if [[ -z ${seenProxy["$proxy"]+x} ]]; then
                    associatedProxies+=("$proxy")
                    seenProxy["$proxy"]=1
                fi

                # Para cada entorno, leer KVM ConfigProxy_<proxy>
                for env in "${environments[@]}"; do
                    kvmEnvList=$(wget --quiet --no-check-certificate \
                        --header="Authorization: Basic $AUTH" \
                        -O - "$APIGEE_URL/environments/$env/keyvaluemaps/")
                    kvmList=()
                    mapfile -t kvmList < <(echo "$kvmEnvList" | jq -r '.[]')

                    if printf '%s\n' "${kvmList[@]}" | grep -qx "ConfigProxy_$proxy"; then
                        kvmDetails=$(wget --quiet --no-check-certificate \
                            --header="Authorization: Basic $AUTH" \
                            -O - "$APIGEE_URL/environments/$env/keyvaluemaps/ConfigProxy_$proxy")
                        kvm=()
                        mapfile -t kvm < <(echo "$kvmDetails" | jq -r '.entry[] .name')

                        for entry in "${kvm[@]}"; do
                            shopt -s nocasematch
                            if [[ "$entry" =~ url ]]; then
                                entryValue=$(wget --quiet --no-check-certificate \
                                    --header="Authorization: Basic $AUTH" \
                                    -O - "$APIGEE_URL/environments/$env/keyvaluemaps/ConfigProxy_$proxy/entries/$entry")
                                url=()
                                mapfile -t url < <(echo "$entryValue" | jq -r '.[]')

                                printf '%s;%s;%s;%s;%s;%s;\n' \
                                    "$app" "$dev" "$product" "$proxy" "$entry" "${url[@]}" \
                                    >> resultado_$timestamp.csv

                                    echo "$app | $dev | $product | $proxy | $entry | ${url[@]} "

                            fi
                        done
                    fi
                done
            done
        done
    done
done

#
# Productos NO asociados a ninguna app
#

echo "Productos sin asociar"

for prod in "${allProducts[@]}"; do
    if [[ -z ${seenProd["$prod"]+x} ]]; then
        nonAssociatedProducts+=("$prod")
    fi
done

for product in "${nonAssociatedProducts[@]}"; do
    prodDetails=$(wget --quiet --no-check-certificate \
        --header="Authorization: Basic $AUTH" \
        -O - "$APIGEE_URL/apiproducts/$product")
    proxyProduct=()
    mapfile -t proxyProduct < <(echo "$prodDetails" | jq -r '.proxies[]')

    for proxy in "${proxyProduct[@]}"; do
        # si este proxy aún no lo tenemos en asociados, lo añadimos
        if [[ -z ${seenProxy["$proxy"]+x} ]]; then
            associatedProxies+=("$proxy")
            seenProxy["$proxy"]=1
        fi

        for env in "${environments[@]}"; do
            kvmEnvList=$(wget --quiet --no-check-certificate \
                --header="Authorization: Basic $AUTH" \
                -O - "$APIGEE_URL/environments/$env/keyvaluemaps/")
            kvmList=()
            mapfile -t kvmList < <(echo "$kvmEnvList" | jq -r '.[]')

            if printf '%s\n' "${kvmList[@]}" | grep -qx "ConfigProxy_$proxy"; then
                kvmDetails=$(wget --quiet --no-check-certificate \
                    --header="Authorization: Basic $AUTH" \
                    -O - "$APIGEE_URL/environments/$env/keyvaluemaps/ConfigProxy_$proxy")
                kvm=()
                mapfile -t kvm < <(echo "$kvmDetails" | jq -r '.entry[] .name')

                for entry in "${kvm[@]}"; do
                    shopt -s nocasematch
                    if [[ "$entry" =~ url ]]; then
                        entryValue=$(wget --quiet --no-check-certificate \
                            --header="Authorization: Basic $AUTH" \
                            -O - "$APIGEE_URL/environments/$env/keyvaluemaps/ConfigProxy_$proxy/entries/$entry")
                        url=()
                        mapfile -t url < <(echo "$entryValue" | jq -r '.[]')

                        printf '%s;%s;%s;%s;%s;%s;\n' \
                            "---" "---" "$product" "$proxy" "$entry" "${url[@]}" \
                            >> resultado_$timestamp.csv


                            echo "---| --- | $product | $proxy | $entry | ${url[@]} "
                    fi
                done
            fi
        done
    done
done

#
# Proxies NO asociados ni a apps ni a productos
#

echo "proxies sin asociar"

for p in "${allProxies[@]}"; do
    if [[ -z ${seenProxy["$p"]+x} ]]; then
        nonAssociatedProxies+=("$p")
    fi
done

for proxy in "${nonAssociatedProxies[@]}"; do
    for env in "${environments[@]}"; do
        kvmEnvList=$(wget --quiet --no-check-certificate \
            --header="Authorization: Basic $AUTH" \
            -O - "$APIGEE_URL/environments/$env/keyvaluemaps/")
        kvmList=()
        mapfile -t kvmList < <(echo "$kvmEnvList" | jq -r '.[]')

        if printf '%s\n' "${kvmList[@]}" | grep -qx "ConfigProxy_$proxy"; then
            kvmDetails=$(wget --quiet --no-check-certificate \
                --header="Authorization: Basic $AUTH" \
                -O - "$APIGEE_URL/environments/$env/keyvaluemaps/ConfigProxy_$proxy")
            kvm=()
            mapfile -t kvm < <(echo "$kvmDetails" | jq -r '.entry[] .name')

            for entry in "${kvm[@]}"; do
                shopt -s nocasematch
                if [[ "$entry" =~ url ]]; then
                    entryValue=$(wget --quiet --no-check-certificate \
                        --header="Authorization: Basic $AUTH" \
                        -O - "$APIGEE_URL/environments/$env/keyvaluemaps/ConfigProxy_$proxy/entries/$entry")
                    url=()
                    mapfile -t url < <(echo "$entryValue" | jq -r '.[]')

                    printf '%s;%s;%s;%s;%s;%s;\n' \
                        "---" "---" " ---" "$proxy" "$entry" "${url[@]}" \
                        >> resultado_$timestamp.csv

                        echo "---| --- | --- | $proxy | $entry | ${url[@]} "
                fi
            done
        fi
    done
done
