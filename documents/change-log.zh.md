# change-log 更新日志

## bofore start

## 2024/3/20 add Bootstrap

选择使用Bootstrap框架作为“前端框架”。

### Bootstrap 安装

rails 7 原生支持bootstrap，所以可以在构建新项目的时候直接通过设置来安装启用Bootstrap。

具体指令如下：

```
rails new edu-tech -c bootstrap -j esbuild
```

在学习如何在rails中引入Bootstrap的过程中踩了一些坑。

- [Rails 7 如何安装 Bootstrap](https://www.bilibili.com/video/BV1w84y1p7eq)

主要的问题是由于rails默认选择importmap这项技术导致的。
解决方案就是绕过去，项目创建时直接选择esbuild而非默认的。

- [Bootstrap 5 + esbuild in Ruby on Rails 7](https://www.youtube.com/watch?v=jyqjecyCv3A)


