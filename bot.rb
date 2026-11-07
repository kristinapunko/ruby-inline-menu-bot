require 'telegram/bot'
require 'dotenv/load'

token = ENV['BOT_TOKEN'].to_s.strip
abort('Помилка: додайте BOT_TOKEN у файл .env.') if token.empty?

MENU_TEXT = 'Оберіть потрібний розділ меню:'.freeze
DOCUMENTATION_URL = 'https://core.telegram.org/bots/api#inlinekeyboardmarkup'.freeze

TIPS = [
  'Додайте .env і *.bak до .gitignore, щоб Git ігнорував токен і резервні копії.',
  'Використовуйте edit_message_text, щоб оновити меню в поточному повідомленні.',
  'Викликайте answer_callback_query після натискання callback-кнопки, щоб прибрати індикатор завантаження.'
].freeze

def callback_button(text, data)
  Telegram::Bot::Types::InlineKeyboardButton.new(text: text, callback_data: data)
end

def main_menu_markup
  Telegram::Bot::Types::InlineKeyboardMarkup.new(
    inline_keyboard: [
      [callback_button('📚 Про проєкт', 'about'), callback_button('⚙️ Стек технологій', 'stack')],
      [callback_button('🎲 Випадкова порада', 'tip_new_msg')],
      [callback_button('❌ Закрити меню', 'close')]
    ]
  )
end

def section_markup(include_documentation: false)
  rows = []
  if include_documentation
    rows << [Telegram::Bot::Types::InlineKeyboardButton.new(
      text: '🔗 Документація Telegram',
      url: DOCUMENTATION_URL
    )]
  end
  rows << [callback_button('⬅️ Назад до меню', 'back_to_main')]
  Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: rows)
end

Telegram::Bot::Client.run(token) do |bot|
  puts 'Бот очікує повідомлень. Для зупинки натисніть Ctrl+C.'

  bot.listen do |update|
    case update
    when Telegram::Bot::Types::CallbackQuery
      bot.api.answer_callback_query(callback_query_id: update.id)
      next unless update.message.is_a?(Telegram::Bot::Types::Message)

      chat_id = update.message.chat.id
      message_id = update.message.message_id

      case update.data
      when 'about'
        bot.api.edit_message_text(
          chat_id: chat_id,
          message_id: message_id,
          text: "📚 Про проєкт\n\nЦей бот демонструє роботу з inline-кнопками та оновлення повідомлень у Telegram. Кнопка нижче відкриває офіційну документацію.",
          reply_markup: section_markup(include_documentation: true)
        )
      when 'stack'
        bot.api.edit_message_text(
          chat_id: chat_id,
          message_id: message_id,
          text: "⚙️ Використані технології\n\n• Ruby — мова програмування\n• telegram-bot-ruby — клієнт Telegram Bot API\n• dotenv — завантаження токена з .env",
          reply_markup: section_markup
        )
      when 'tip_new_msg'
        bot.api.send_message(chat_id: chat_id, text: "💡 Порада розробнику\n\n#{TIPS.sample}")
      when 'back_to_main'
        bot.api.edit_message_text(
          chat_id: chat_id,
          message_id: message_id,
          text: MENU_TEXT,
          reply_markup: main_menu_markup
        )
      when 'close'
        bot.api.edit_message_text(
          chat_id: chat_id,
          message_id: message_id,
          text: 'Меню закрито. Щоб відкрити його знову, введіть /menu.'
        )
      end
    when Telegram::Bot::Types::Message
      next unless update.text

      case update.text.strip
      when '/start'
        name = update.from&.first_name
        greeting = name ? "Привіт, #{name}! 👋" : 'Привіт! 👋'
        bot.api.send_message(
          chat_id: update.chat.id,
          text: "#{greeting}\nЯ бот з інтерактивним меню на Ruby. Введіть /menu, щоб відкрити меню."
        )
      when '/menu'
        bot.api.send_message(chat_id: update.chat.id, text: MENU_TEXT, reply_markup: main_menu_markup)
      when '/help'
        bot.api.send_message(
          chat_id: update.chat.id,
          text: "Доступні команди\n/start — привітання\n/menu — відкрити меню з кнопками\n/help — довідка"
        )
      else
        bot.api.send_message(
          chat_id: update.chat.id,
          text: 'Невідома команда. Скористайтеся /menu або /help.'
        )
      end
    end
  rescue Telegram::Bot::Exceptions::ResponseError => e
    warn "Помилка Telegram API: #{e.message.gsub(token, '[TOKEN]')}"
  end
end
