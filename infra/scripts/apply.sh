#!/usr/bin/env bash
# ============================================================================
# apply.sh — 在华为云落地本仓库的基础设施（VPC + 互联网应用型 ELB + IAM Agency）
#
# 凭据仅来自环境变量（绝不写死 AK/SK）：
#   export HW_ACCESS_KEY=...      # 仅会话级，命令结束即失效
#   export HW_SECRET_KEY=...
#   export HW_REGION_NAME=cn-north-4
#
# 用法：
#   HW_ACCESS_KEY=xxx HW_SECRET_KEY=yyy HW_REGION_NAME=cn-north-4 \
#     bash apply.sh [env] [account]
# 默认 env=dev, account=555555555555（account 仅用于打标签）
#
# 注意：本模板默认【不创建公网 NAT 网关】（vpc_enable_nat_gateway=false），
#       仅 ELB 绑定 1 个公网 EIP。
# ============================================================================
set -euo pipefail

cd "$(dirname "$0")/.."

ENV="${1:-dev}"
ACCOUNT="${2:-555555555555}"

: "${HW_ACCESS_KEY:?请先设置环境变量 HW_ACCESS_KEY}"
: "${HW_SECRET_KEY:?请先设置环境变量 HW_SECRET_KEY}"
: "${HW_REGION_NAME:?请先设置环境变量 HW_REGION_NAME}"

echo "==> [1/4] terraform init"
terraform init

echo "==> [2/4] terraform plan (env=$ENV, account=$ACCOUNT)"
terraform plan \
  -var="env=$ENV" \
  -var="account=$ACCOUNT" \
  -var="vpc_enable_nat_gateway=false" \
  -out=tfplan

echo "==> [3/4] 请核对上方 plan 输出（应显示 ELB / EIP / VPC / 子网 / 安全组 / IAM Agency，无 NAT）"
echo "==> 确认无误后执行：terraform apply tfplan"
read -r -p "是否立即 apply？(yes/no) " ANS
if [ "$ANS" != "yes" ]; then
  echo "已取消，未创建任何资源。可稍后手动执行：terraform apply tfplan"
  exit 0
fi

echo "==> [4/4] terraform apply"
terraform apply tfplan

echo "==> 完成。取 ELB 公网地址："
terraform output -raw elb_public_ip
echo ""
echo "==> 验证监听器（空后端池，预期 404）："
echo "    curl -i http://$(terraform output -raw elb_public_ip):80/"
echo "==> 不再需要时释放：bash scripts/run-tf-regional-destroy.sh（并手动 terraform destroy 根模块）"
