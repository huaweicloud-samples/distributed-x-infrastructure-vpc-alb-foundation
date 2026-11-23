#!/bin/bash
# NOTE: the IAM agency (0b1-wan-ken0be) is created MANUALLY in the console
# (IAM > 委托 > 创建委托, trusted service = ECS), NOT via Terraform.
# Reason: huaweicloud provider v1.96.1 maps `delegated_service_name` to a
# domain lookup that always 404s for "弹性云服务器", so an ECS-trusted agency
# cannot be created through this provider version.
#
# Therefore there is NOTHING for Terraform to destroy here. To remove the
# agency, delete it manually in the console. This script just informs you.
echo "No Terraform-managed global resources in this repo."
echo "The IAM agency '0b1-wan-ken0be' was created manually in the console"
echo "(IAM > 委托). Delete it there if you no longer need it."
