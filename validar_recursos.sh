vpc_id=$(aws ec2 describe-vpcs --filters Name=isDefault,Values=true --query "Vpcs[0].VpcId" --output text 2>/dev/null)

# Listar todas as VPCs
vpc_ids=$(aws ec2 describe-vpcs --query "Vpcs[].VpcId" --output text)


for vpc_id in $vpc_ids; do
  # Procurar security group 'bia-dev' nesta VPC
  security_group_id=$(aws ec2 describe-security-groups --filters Name=group-name,Values=bia-dev Name=vpc-id,Values=$vpc_id --query "SecurityGroups[0].GroupId" --output text 2>/dev/null)
  if [ $? -eq 0 ] && [ "$security_group_id" != "None" ]; then
    echo "Validando recursos na VPC: $vpc_id ---"

    # Validar subnet na zona us-east-1a
    subnet_id=$(aws ec2 describe-subnets --filters Name=vpc-id,Values=$vpc_id Name=availabilityZone,Values=us-east-1a --query "Subnets[0].SubnetId" --output text 2>/dev/null)
    if [ $? -eq 0 ] && [ "$subnet_id" != "None" ]; then
      echo "[OK] Tudo certo com a Subnet na zona us-east-1a"
    else
      echo ">[ERRO] Tenho um problema ao retornar a subnet da zona a na VPC $vpc_id. Será se existe uma subnet na zona A?"
    fi

    echo "[OK] Security Group bia-dev foi criado na VPC $vpc_id"

    # Validar inbound rule para o security group 'bia-dev'
    inbound_rule=$(aws ec2 describe-security-groups --group-ids $security_group_id --query 'SecurityGroups[0].IpPermissions[?FromPort==`3001` && IpRanges[?CidrIp==`0.0.0.0/0`]]' --output text)
    if [ -n "$inbound_rule" ]; then
      echo " [OK] Regra de entrada está ok"
    else
      echo " >[ERRO] Regra de entrada para a porta 3001 não encontrada ou não está aberta para o mundo todo. Reveja a aula do Henrylle"
    fi

    # Validar outbound rule para o security group 'bia-dev'
    outbound_rule=$(aws ec2 describe-security-groups --group-ids $security_group_id --query "SecurityGroups[0].IpPermissionsEgress[?IpProtocol=='-1' && IpRanges[?CidrIp=='0.0.0.0/0']]" --output text)
    if [ -n "$outbound_rule" ]; then
      echo " [OK] Regra de saída está correta"
    else
      echo " >[ERRO] Regra de saída para o mundo não encontrada. Reveja a aula do Henrylle"
    fi
  fi
done

# Validar role IAM
if aws iam get-role --role-name role-acesso-ssm &>/dev/null; then
  echo "[OK] Tudo certo com a role 'role-acesso-ssm'"
else
  echo ">[ERRO] A role 'role-acesso-ssm' não existe"
fi