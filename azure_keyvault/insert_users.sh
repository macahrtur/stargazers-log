#!/bin/bash
if [ -z "$1" ]; then
    echo "Use: $0 <des|pre|pro> [file1.yml file2.yml ...]"
    exit 1
fi

ENTORNO="$1"
shift

if [ "$#" -gt 0 ]; then
    files=("$@")
else
    files=(*.yml)
fi

for file in "${files[@]}"; do
    if [ ! -f "$file" ]; then
        echo "Skip: '$file' not found"
        continue
    fi

    keyvault=$(basename "$file" .yml)
    if [[ "$keyvault" == *-env-* ]]; then
        keyvault=$(echo "$keyvault" | sed "s/-env-/-$ENTORNO-/")
    fi

    # Verificar que no existan valores duplicados
    echo ""
    echo "Key Vault: $keyvault"
    echo "Verifying duplicates ..."
    claves=$(yq -r ".[].$ENTORNO" < "$file")
    duplicados=$(echo "$claves" | sort | uniq -d)
    if [[ "$duplicados" ]]; then
        echo "-----------------------------------------------------"
        echo -e "WARNING: Duplicate values ​​found in more than one key: \n$duplicados"
        echo "-----------------------------------------------------"
    fi

    # # Insertar secretos
    # echo "Inserting secrets ..."
    # keys=$(yq -r ". | keys[]" < "$file")
    # for user in $keys; do
    #     value_user=$(yq -r ".$user.$ENTORNO" < "$file")

    #     # Solo procesar si no es null
    #     if [[ "$value_user" != "null" ]]; then
    #         if [[ "$user" == pass* ]]; then
    #             # Pass* se inserta incluso si está vacío
    #             if az keyvault secret show --only-show-errors --vault-name "$keyvault" --name "$user" >/dev/null 2>&1; then
    #                 echo "Password $user exists - SKIP"
    #             else
    #                 az keyvault secret set --only-show-errors --output "none" --vault-name "$keyvault" --name "$user" --value "$value_user"
    #                 echo "Set secret $user"
    #             fi
    #         else
    #             # User* solo si tiene valor
    #             if [[ -n "$value_user" ]]; then
    #                 az keyvault secret set --only-show-errors --output "none" --vault-name "$keyvault" --name "$user" --value "$value_user"
    #                 echo "Set secret $user"
    #             fi
    #         fi
    #     fi
    # done

    # # Idempotencia
    # echo "Setting idempotency ..."
    # # Obtener usuarios en el Key Vault y eliminar los que no estén en el repo
    # kvusers=$(az keyvault secret list --only-show-errors --output "table" --vault-name "$keyvault" | grep user | awk '{print $1}')
    # for secretname in $kvusers; do
    #     userinyaml=$(yq -r ".$secretname.$ENTORNO" < "$file")
    #     if  [[ "$userinyaml" == "null" ]]; then
    #         az keyvault secret delete --only-show-errors --output "table" --vault-name "$keyvault" --name "$secretname"
    #         echo "$secretname not found in yaml. Secret removed"
    #         # Obtener passwords huérfanas en el Key Vault y eliminarlas
    #         passname=$(echo "$secretname" | sed "s/user/pass/")
    #         kvpassword=$(az keyvault secret list --only-show-errors --output "table" --vault-name "$keyvault" | grep "$passname" | awk '{print $1}')
    #         if [[ "$kvpassword" ]]; then
    #             az keyvault secret delete --only-show-errors --output "table" --vault-name "$keyvault" --name "$passname"
    #             echo "$passname found in Key Vault. Orphan secret removed"
    #         fi
    #     fi
    done
done