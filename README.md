# AGIC shared install

ほぼ、環境に依存しない形に整備しました。

## 環境変数の設定

リソースグループ名とかに影響するのでかぶりのない名前にしてください。

```sh
appName=<application-name-you-want>
subscriptionName=<your-subscription-Name>
```

サブスクリプション名の一覧は以下で取得できます。

```sh
az account list --query '[].name'
```

## Azureリソースのデプロイ

ワンコマンドでAzure CNIを利用したAKSクラスタが2つとAppGWがデプロイされます。

生まれてきたことに感謝しましょう。

```sh
az deployment sub create -f deploy.bicep -l japaneast -p appName=$appName
```

## Helm関連のインストール

Helm v3とAGICパッケージのインストールまで一気に行います。

WSL前提ですが、すでにHelmがインストールされてても気にせず実行して（たぶん）大丈夫と思います。

```sh
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash \
&& helm repo add application-gateway-kubernetes-ingress \
https://appgwingress.blob.core.windows.net/ingress-azure-helm-package/ \
&& helm repo update
```

## サービスプリンシパル(SP)およびhelm-configの作成

SPは共有し、helmのconfigは2つのAKSクラスターについてそれぞれ作成します。

```sh
if [ -f auth.json ]; then rm auth.json; fi \
&& az ad sp create-for-rbac --name $appName --sdk-auth > auth.json \
&& secretJSON=$(cat auth.json | base64 -w0) \
&& subscriptionId=$(az account list -o tsv --query "[?@.name=='$subscriptionName'].id") \
&& resourceGroupName=rg-${appName} \
&& applicationGatewayName=${appName}-appgw \
&& apiServerAddress=$(az aks show -g rg-$appName -n ${appName}-aks1 -o tsv --query fqdn) \
&& if [ -f helm-config-1.json ]; then rm helm-config-1.yml; fi \
&& if [ -f helm-config-2.json ]; then rm helm-config-2.yml; fi \
&& $(cat <<EOL > helm-config-1.yml
verbosityLevel: 3
appgw:
    subscriptionId: $subscriptionId
    resourceGroup: $resourceGroupName
    name: $applicationGatewayName
    shared: true
armAuth:
    type: servicePrincipal
    secretJSON: $secretJSON
rbac:
    enabled: true
aksClusterConfiguration:
    apiServerAddress: $apiServerAddress
EOL
) \
&& apiServerAddress=$(az aks show -g rg-$appName -n ${appName}-aks2 -o tsv --query fqdn) \
&& $(cat <<EOS > helm-config-2.yml
verbosityLevel: 3
appgw:
    subscriptionId: $subscriptionId
    resourceGroup: $resourceGroupName
    name: $applicationGatewayName
    shared: true
armAuth:
    type: servicePrincipal
    secretJSON: $secretJSON
rbac:
    enabled: true
aksClusterConfiguration:
    apiServerAddress: $apiServerAddress
EOS
)
```

## installとdeploy

コマンドを連結し一気にいきます。

```sh
az aks get-credentials -g rg-$appName -n ${appName}-aks1 \
&& az aks get-credentials -g rg-$appName -n ${appName}-aks2 \
&& helm install --kube-context ${appName}-aks1 -f helm-config-1.yml application-gateway-kubernetes-ingress/ingress-azure --generate-name \
&& helm install --kube-context ${appName}-aks2 -f helm-config-2.yml application-gateway-kubernetes-ingress/ingress-azure --generate-name \
&& kubectl apply -f prohibit-fugaginx.yml --context ${appName}-aks1 \
&& kubectl apply -f prohibit-hogeginx.yml --context ${appName}-aks2 \
&& kubectl delete AzureIngressProhibitedTarget prohibit-all-targets --context ${appName}-aks1 \
&& kubectl delete AzureIngressProhibitedTarget prohibit-all-targets --context ${appName}-aks2 \
&& kubectl apply -f hogeginx.yml --context ${appName}-aks1 \
&& kubectl apply -f fugaginx.yml --context ${appName}-aks2
```

## 疎通確認

うまくいっていれば、2つとも200で応答が返ってくるはずです。

デプロイしてから1分程度待たないと失敗するかもしれません。

```sh
publicIp=$(kubectl get ingress --context ${appName}-aks1 -o=jsonpath='{$..ip}') \
&& curl -I -H "Host: hogeginx.com" $publicIp \
&& curl -I -H "Host: fugaginx.com" $publicIp
```

上記により、ほぼ直接の文字入力を必要とせずにコピペでshared疎通の確認までいけるはずです。

## リソースの削除

リソースグループとサービスプリンシパルを削除します。

```sh
az group delete -n rg-$appName --no-wait -y \
&& az ad sp delete --id $(cat auth.json | jq -r .clientId)
```
