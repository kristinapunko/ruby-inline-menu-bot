require 'telegram/bot'
require 'dotenv/load'

token = ENV['BOT_TOKEN']
abort('Помилка: не знайдено BOT_TOKEN у файлі .env') if token.nil? || token.empty?

# Допоміжний метод для формування головного меню з inline-кнопками
def main_menu_markup
  kb = [
    [
      Telegram::Bot::Types::InlineKeyboardButton.new(text: '📚 Про проєкт', callback_data: 'about'),
      Telegram::Bot::Types::InlineKeyboardButton.new(text: '⚙️ Стек технологій', callback_data: 'stack')
    ],
    [
      Telegram::Bot::Types::InlineKeyboardButton.new(text: '🎲 Випадкова порада', callback_data: 'tip_new_msg')
    ],
    [
      Telegram::Bot::Types::InlineKeyboardButton.new(text: '❌ Закрити меню', callback_data: 'close')
    ]
  ]
  Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb)
end

# Кнопка повернення до головного меню
def back_button_markup
  kb = [
    [Telegram::Bot::Types::InlineKeyboardButton.new(text: '⬅️ Назад до меню', callback_data: 'back_to_main')]
  ]
  Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb)
end

TIPS = [
  'Використовуйте .env та .gitignore, щоб не публікувати API-токени в репозиторії.',
  'У Ruby метод edit_message_text дозволяє оновлювати меню без створення нових повідомлень у чаті.',
  'Завжди викликайте answer_callback_query, щоб прибрати індикатор завантаження на кнопці в користувача.'
].freeze

puts 'Бот успішно запущений і очікує повідомлень...'

Telegram::Bot::Client.run(token) do |bot|
  bot.listen do |update|
    case update
    # 1. Обробка натискання на Inline-кнопки
    when Telegram::Bot::Types::CallbackQuery
      chat_id = update.message.chat.id
      message_id = update.message.message_id

      # Обов'язкове підтвердження натискання для Telegram API
      bot.api.answer_callback_query(callback_query_id: update.id)

      case update.data
      when 'about'
        bot.api.edit_message_text(
          chat_id: chat_id,
          message_id: message_id,
          text: "📚 *Про проєкт*\n\nЦей бот розроблений мовою Ruby для демонстрації роботи з Inline-клавіатурами (`InlineKeyboardMarkup`) та динамічного оновлення повідомлень.",
          parse_mode: 'Markdown',
          reply_markup: back_button_markup
        )
      when 'stack'
        bot.api.edit_message_text(
          chat_id: chat_id,
          message_id: message_id,
          text: "⚙️ *Використані технології*\n\n• Мова: Ruby\n• Бібліотека: `telegram-bot-ruby`\n• Конфігурація: `dotenv`",
          parse_mode: 'Markdown',
          reply_markup: back_button_markup
        )
      when 'tip_new_msg'
        # Надсилання нового повідомлення у відповідь на натискання кнопки
        bot.api.send_message(
          chat_id: chat_id,
          text: "💡 *Порада розробнику:*\n#{TIPS.sample}",
          parse_mode: 'Markdown'
        )
      when 'back_to_main'
        bot.api.edit_message_text(
          chat_id: chat_id,
          message_id: message_id,
          text: 'Оберіть потрібний розділ меню:',
          reply_markup: main_menu_markup
        )
      when 'close'
        bot.api.edit_message_text(
          chat_id: chat_id,
          message_id: message_id,
          text: 'Меню закрито. Щоб відкрити його знову, введіть /menu.'
        )
      end

    # 2. Обробка текстових команд
    when Telegram::Bot::Types::Message
      next unless update.text

      case update.text.strip
      when '/start'
        bot.api.send_message(
          chat_id: update.chat.id,
          text: "Привіт, #{update.from.first_name}! 👋\nЯ бот з інтерактивним меню на Ruby.\n\nВведіть команду /menu, щоб відкрити панель керування."
        )
      when '/menu'
        bot.api.send_message(
          chat_id: update.chat.id,
          text: 'Оберіть потрібний розділ меню:',
          reply_markup: main_menu_markup
        )
      when '/help'
        bot.api.send_message(
          chat_id: update.chat.id,
          text: "Доступні команди:\n/start — запуск бота\n/menu — відкрити інтерактивне меню з кнопками\n/help — довідка"
        )
      else
        bot.api.send_message(
          chat_id: update.chat.id,
          text: 'Невідома команда. Скористайтеся /menu для виклику кнопок або /help для довідки.'
        )
      end
    end
  rescue Telegram::Bot::Exceptions::ResponseError => e
    warn "Помилка Telegram API: #{e.message}"
  rescue StandardError => e
    warn "Непередбачена помилка: #{e.class} — #{e.message}"
  end
end