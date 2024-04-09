# rails-指南

## rails 信条

强烈建议在开始学习rails前先阅读rails信条。

> [rails offical site](https://rubyonrails.org/doctrine)

- Optimize for programmer happiness 程序员的幸福最大化
- Convention over Configuration 约定优于配置
- The menu is omakase 主厨精选
- No one paradigm 没有范例
- Exalt beautiful code 推崇优美的代码
- Provide sharp knives 提供锋利的刀具
- Value integrated systems 整合系统的价值
- Progress over stability 进步优于稳定
- Push up a big tent 团结向上

> "Omakase"（お任せ）是日语词汇，意为“托付”或“由厨师挑选”。

### Convention over Configuration 约定优于配置

>当提到 Rails 的“CoC”时，通常是指“CoC（Convention over Configuration）”，即“约定优于配置”。

## rails 安装

一般使用 gem 安装 rails 。

```bash
gem install rails
```

gem 是ruby的包管理器，如果你安装了ruby的话就可以使用gem了。有趣的是，通过gem安装的包，也被称呼为gems。

> ruby的gem，好比node的npm，python的pip，debian系Linux发行版的apt。

建议生产环境避免使用apt安装ruby。debian系的linux发行版使用apt安装的软件会要求使用sudo权限运行。
如果你使用apt安装的ruby的gem去安装rails，这样安装的rails的大部分指令都得用sudo权限才能运行，而rails官方建议避免使用sudo权限运行rails。

> 我猜测这样做会存在一些安全问题，比如黑客控制了rails App，然后使用具有sudo权限的rails命令对系统造成破坏。

使用rbenv或者rvm可以很好的避免这个问题。

> rbenv和rvm是ruby的ruby的环境管理工具，类似于python的conda。本质是方便开发者在不同项目中使用不同版本ruby以及管理ruby相关依赖规避gem之间的冲突。

我个人是建议使用它们的，因为有些额外的好处：

- 切换不同版本ruby时会自动切换到到对应版本所支持的rails。


## rails 命令

当你使用gem安装好rails后你就可以在命令行里使用rails命令了。

### 查看rails版本

```bash
rails -v
```

>Rails 7.1.3.2

这是我的rails版本，具体会是什么版本，取决于你实际安装了哪个版本。

### 生成rails项目

```bash
rails new App1
```

### `rails`和`bin/rails`的区别

当你生成好了你的rails项目后，你就应该进入到你项目目录里，然后改为使用`bin/rails`而不是rails。

这样做的好处是避免使用rails指令时误使用项目外的rails操作，为什么要避免这种情况？

一种可能的情况是你项目rails版本和你系统中安装的rails版本不一致。
这种情况下使用非gems对应的版本的rails去操作他们就会产生冲突。

虽然很多情况下rails很智能，会根据你所在的rails项目文件夹执行相应版本的rails，或者选择使用项目目录下的rails。

另一种情况是你离开rails项目目录而没有察觉，然后使用了rails命令造成了并非你想要的结果。
如果你使用`bin/rails`的话，终端就会提示你命令未知。

> 我后面的指令我都会写`bin/rails`

### 生成迁移文件

rails实现一套迁移工具，通过迁移工具，你可以编写ruby语句来管理你的数据表。

约定优于配置，在迁移上rails也有一些良好的规范。

```bash
bin/rails generate migration <迁移文件名>
```

执行这段指令将在`db/migrate`目录下手生成一个带有日期编号和文件名的`.rb`尾缀的迁移文件。
注意，`<迁移文件名>`应该按照驼峰命名法编写，同时文件名应该具有明确的行为含义。

生成好迁移文件后，你就可以在迁移文件中是用rails的方法来完成想要的数据表操作了。

在进行迁移操作前你可以任意修改你最新创建的迁移文件，但在迁移执行后，请不要修改你执行过迁移操作的迁移文件。
这有违rails的理念。
如果你有按照rails约定编写迁移文件的话，迁移文件能够准确的记录你的数据表的一部分变更情况。

如果你发现你此前执行过的迁移文件未能满足的你的需求，你应该重新生成另一个迁移文件来实现，而不是修改之前的迁移文件。

### 执行迁移

如果你已经编写好了你的迁移文件，那么可以执行下面的指令，来使你新写的迁移文件生效。

```bash
bin/rails db:migrate
```

## Model

## Controller

## View

### rails erb文件

rails本身是一个全栈Web框架，如果采用纯ruby方案的话，那么前端会用erb文件去写。

erb文件实际上是一个可嵌入ruby代码的html文件，很多情况下视图层的文件尾缀为`.html.erb`。

ruby代码使用这个标签来嵌入到erb文件中`<%= %>`。

实际上erb文件的内容最终会被转化为纯html内容。rails所做的工作就是把ruby代码标签部分按照rails的规则去转换成对应的html标签。

> 这玩意和php和jsp十分相似。

### link_to

## rails 路由

rails的路由主要由`routes.rb`文件设置。
这个文件位于项目根目录下的`config`文件夹里。

### routes.rb

注意如果你的页面里出现你创建的resources里的方法生成的路径。
那么请确保这个页面的路由配置位于相关resources的路由配置之后。

否则会出现一些问题。

比如调用`course_path(course)`
, 应该返回`courses/4`却变成`/course.4`


```ruby
Rails.application.routes.draw do

  # courses
  resources :courses do
    resources :resources, only: [:create]
    resources :activities, only: [:create]
    member do
      get "information", to: 'courses#show_information'
      get 'edit_information', to: 'courses#edit_information', as: 'edit_information'
      get "resource", to: 'courses#show_resource'
      get "activity", to: 'courses#show_activity'
    end
  end

  # navbar
  get "/home", to: "home#index"
  get "/course", to: "courses#index"
  get "/classroom", to: "classrooms#index"
  get "/about", to: "about#index"
  get "/upload", to: "uploads#index"

  get "up" => "rails/health#show", as: :rails_health_check

  # 根路径
  root "home#index"
end
```




