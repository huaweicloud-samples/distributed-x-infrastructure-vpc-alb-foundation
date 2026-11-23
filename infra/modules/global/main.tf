terraform {
  required_providers {
    huaweicloud = {
      source  = "huaweicloud/huaweicloud"
      version = ">= 1.40.0"
    }
  }
}

# ===========================================================================
# Global (account-level) resource: IAM Agency (委托)
# ---------------------------------------------------------------------------
# Provides an IAM Agency (委托) with trust to the ECS service, used so that
# compute instances can obtain temporary credentials for cross-service calls.
# Agencies are account-global (no region).
#
# IMPORTANT — NOT CREATED VIA TERRAFORM:
# The huaweicloud provider v1.96.1 maps `delegated_service_name` to a *domain*
# lookup, so an ECS-trusted agency cannot be created through this provider
# (the domain lookup fails). This module is therefore NOT
# invoked from the root (see infra/main.tf — the `module "global"` call is
# commented out). Create the agency manually in the console instead:
#
#   控制台 > IAM > 委托 > 创建委托
#     名称:       0b1-wan-ken0be
#     委托类型:   普通账号 / 云服务
#     被信任服务: ECS
#     权限:       只读 (readonly) —— 按实际业务裁剪为最小权限
#
# "readonly" is used here as a safe placeholder — trim to real need.
# ===========================================================================
