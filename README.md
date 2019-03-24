# GodUploader
KMC内部で使うアップローダーです。

Ruby 2.6.1

# インストール
```
bundle install --path vendor/bundle
```

# 起動
```
bundle exec ruby app.rb
```

https://localhost:4567

# Gyazoを用いたSlackへのアップロード自動通知機能の使用方法
``` yaml:config.yml
:slack_url: YOUR_SLACK_URL
:gyazo_token: YOUR_GYAZO_TOKEN
```

と書かれたconfig.ymlを `/config/` 内に配置してください。
