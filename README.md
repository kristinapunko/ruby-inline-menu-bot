# Ruby Inline Menu Telegram Bot

Telegram-бот із вбудованою інтерактивною клавіатурою (Inline Keyboard), реалізований мовою Ruby з використанням бібліотеки `telegram-bot-ruby`.

## Функціонал
- Вітання користувача та довідка за командами `/start` і `/help`.
- Виклик багаторівневого інтерактивного меню за командою `/menu`.
- Динамічна зміна тексту поточного повідомлення при навігації по пунктах меню (`edit_message_text`).
- Надсилання окремого повідомлення з випадковою порадою при натисканні відповідної кнопки (`send_message`).

## Встановлення та запуск

1. Клонуйте репозиторій:
   ```bash
   git clone [https://github.com/ваш-логін/ruby-inline-menu-bot.git](https://github.com/ваш-логін/ruby-inline-menu-bot.git)
   cd ruby-inline-menu-bot