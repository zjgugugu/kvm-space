# 项目实施计划与决策记录

## 已确认决策
1. **端口**: 总控界面 9091, 管理控制台 8444（避免与真实产品冲突）
2. **模式**: 只需libvirt模式，不保留mock模式
3. **技术栈**: 保持 Node.js + Vue3 + Element Plus（不改为Java/Grails）
4. **侵权**: 不使用原产品源码，全部自主实现
5. **开发流程**: Windows上修改代码 → SCP到Linux验证 → git存档
6. **权限**: 涉及系统权限/删除操作需用户确认，安装工具不需确认

## SSH配置
- **免密登录**: ✅ 已配置
- **持久化**: ✅ 公钥已加入共享存储 /home/kylin-ksvd/.ksvd/authorized_keys
- **验证**: 每分钟同步后仍然有效

## 进度追踪

### Phase 1: 环境准备与产品调研
- [x] SSH免密登录
- [x] 禁用authorized_keys自动刷新（添加到共享存储）
- [ ] MC管理控制台登录和页面抓取（需解决AES加密）
- [ ] Cockpit总控界面分析
- [ ] 服务器详细架构分析
- [ ] KSVD工具和配置分析
- [ ] 数据库结构分析（MariaDB + HSQLDB）
- [ ] API接口全面收集

### Phase 2-6: 见 session plan

## 待解决问题
1. MC登录使用AES加密，需要找到KSVD.encrypt()实现（在mc.js中）
2. 需要安装Node.js和npm来运行我们的项目（服务器上或Windows上）
