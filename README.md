# VPN_lab

Сложить все файлы в одну папку

```Bash
vagrant up
```

Запустить скрипт с выбором типа VPN и сервера\клиент (Usage: /vagrant/setup.sh [tap|tun] [server|client])

Для сервера tap
```Bash
/vagrant/setup.sh tap server, крипт будет предлагать скопировать ключ для клиентской машины
```
Для клиента tap, крипт будет предлагать скопировать ключ для клиентской машины
```Bash
/vagrant/setup.sh tap client
```
Проверяем:
<img width="1902" height="455" alt="image" src="https://github.com/user-attachments/assets/93db0ed3-a1d6-4dc8-8a16-953949af1c55" />

Повторяем все тоже для TUN
Для сервера tun, скрипт будет предлагать скопировать ключ для клиентской машины
```Bash
/vagrant/setup.sh tun server
```
Для клиента tap, крипт будет предлагать скопировать ключ для клиентской машины
```Bash
/vagrant/setup.sh tun client
```

Проверяем:
<img width="1901" height="495" alt="image" src="https://github.com/user-attachments/assets/62c51e6d-b53b-4b12-8da8-bd3239363cd3" />
