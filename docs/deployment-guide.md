# 华为云 Infrastructure 资源实践（部署指导书）

> 一步步在华为云落地本实践的 Terraform 代码（位于 `infra/`）。

## 1. 前置条件

| 项目 | 要求 |
|------|------|
| 华为云账号 | 具备 VPC、ELB、IAM、EIP 的创建权限（本模板默认不创建 NAT） |
| 访问密钥 | `HW_ACCESS_KEY` / `HW_SECRET_KEY`（仅通过环境变量注入，**禁止硬编码**） |
| 区域 | 默认 `cn-north-4`，可用 `-var="region=..."` 覆盖 |
| Terraform | `>= 1.3.0` |
| huaweicloud Provider | `>= 1.40.0` |

```bash
# 凭据通过环境变量注入
export HW_ACCESS_KEY=<HW_ACCESS_KEY>
export HW_SECRET_KEY=<HW_SECRET_KEY>
export HW_REGION_NAME=cn-north-4 # 可选，provider.region 也会设置
```

## 2. 初始化

```bash
cd infra
terraform init
# 如使用 OBS 远程状态，先在 provider.tf 打开 backend "obs" 块并填入 bucket/endpoint
```

## 3. 预览变更

```bash
terraform plan \
-var="env=dev" \
-var="region=cn-north-4" \
-var-file="environments/dev/research/variables.tfvars"
```

> **apply 前请先复核规格。**

## 4. 部署

```bash
terraform apply \
-var="env=dev" \
-var="region=cn-north-4" \
-var-file="environments/dev/research/variables.tfvars"
```

部署完成后查看输出：

```bash
terraform output elb_public_ip # 负载均衡公网 IP（EIP）
terraform output vpc_id
```

> IAM 委托（Agency）当前由控制台手动创建（见 README「IAM Agency 手动创建」），不通过 `terraform output agency_name` 获取。

浏览器访问 `http://<elb_public_ip>` 即可到达监听器（默认转发到后端池；池内无成员时返回 404）。

## 5. 多环境与多团队

`environments/<env>/<team>/` 下提供了 `.tfvars` 选择文件（`account` 占位在 `variables.tfvars` 中）。通过 `-var="env=..."` 与 `-var-file=` 组合切换环境/团队。

## 6. 清理资源

```bash
terraform destroy \
-var="env=dev" \
-var="region=cn-north-4" \
-var-file="environments/dev/research/variables.tfvars"
```

> 若销毁时报 `listener is using this loadbalancer` 冲突（ELB 监听器与后端池的解绑顺序问题），先单独销毁池与监听器：
> ```bash
> terraform destroy -target=huaweicloud_elb_pool.ext_lb -target=huaweicloud_elb_listener.ext_lb
> terraform destroy # 再整体销毁
> ```

## 7. 让入口真正返回内容（可选）

本实践监听器在空池时返回 404；如需返回自定义文案/真实服务，向池内注册一个后端：

```hcl
resource "huaweicloud_elb_member" "demo" {
pool_id = huaweicloud_elb_pool.ext_lb.id
subnet_id = module.vpc.public_subnet_ipv4_ids[0] # 使用 ipv4_subnet_id
address = "<后端实例内网IP>"
protocol_port = 80
}
```

后端实例上用 nginx 返回目标文案即可。`ignore_changes` 等运行期字段本实践暂未涉及。

## 8. 区域与规格注意

- **ELB L7 flavor 必须按目标 region 实查**：`terraform console` 中执行
```hcl
data "huaweicloud_elb_flavors" "l7" { type = "L7" }
data.huaweicloud_elb_flavors.l7.flavors
```
将查到的名称填入变量 `elb_l7_flavor_name`（默认 `L7_flavor.elb.s1.small`，不同 region 名称可能不同）。
- EIP 带宽 `size=5`（调试期最小），生产按需调大。
