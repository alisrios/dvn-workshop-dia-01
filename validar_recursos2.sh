#!/bin/bash

vpc_id="vpc-060bb4f973c6ba779"

# Verificação da VPC
if [[ -n "$vpc_id" ]]; then
  echo "[OK] Tudo certo com a VPC"
else
  echo ">[ERRO] Tenho um problema ao retornar a VPC default. Será se ela existe?"
fi

# Verificação da Subnet na zona us-east-1a
subnet_id=$(aws ec2 describe-subnets \
  --filters Name=vpc-id,Values=$vpc_id Name=availabilityZone,Values=us-east-1a \
  --query "Subnets[0].SubnetId" --output text 2>/dev/null)

if [[ -n "$subnet_id" && "$subnet_id" != "None" ]]; then
  echo "[OK] Tudo certo com a Subnet"
else
  echo ">[ERRO] Tenho um problema ao retornar a subnet da zona a. Será se existe uma subnet na zona A?"
fi

# Verificação do Security Group
security_group_id=$(aws ec2 describe-security-groups \
  --filters Name=group-name,Values=bia-dev Name=vpc-id,Values=$vpc_id \
  --query "SecurityGroups[0].GroupId" --output text 2>/dev/null)

if [[ -n "$security_group_id" && "$security_group_id" != "None" ]]; then
  echo "[OK] Security Group bia-dev foi criado"

  # Validar inbound rule (porta 3001 aberta para 0.0.0.0/0)
  inbound_rule=$(aws ec2 describe-security-groups \
    --group-ids $security_group_id \
    --query "SecurityGroups[0].IpPermissions[?FromPort==\`3001\` && IpRanges[?CidrIp=='0.0.0.0/0']]" \
    --output text)

  if [[ -n "$inbound_rule" ]]; then
    echo " [OK] Regra de entrada está ok"
  else
    echo " >[ERRO] Regra de entrada para a porta 3001 não encontrada ou não está aberta para o mundo todo. Reveja a aula do Henrylle"
  fi

  # Validar outbound rule (0.0.0.0/0 liberado)
  outbound_rule=$(aws ec2 describe-security-groups \
    --group-ids $security_group_id \
    --query "SecurityGroups[0].IpPermissionsEgress[?IpProtocol=='-1' && IpRanges[?CidrIp=='0.0.0.0/0']]" \
    --output text)

  if [[ -n "$outbound_rule" ]]; then
    echo " [OK] Regra de saída está correta"
  else
    echo " >[ERRO] Regra de saída para o mundo não encontrada. Reveja a aula do Henrylle"
  fi

else
  echo ">[ERRO] Não achei o Security Group bia-dev. Ele foi criado?"
fi

# Verificação da role IAM
if aws iam get-role --role-name role-acesso-ssm &>/dev/null; then
  echo "[OK] Tudo certo com a role 'role-acesso-ssm'"
else
  echo ">[ERRO] A role 'role-acesso-ssm' não existe"
fi
