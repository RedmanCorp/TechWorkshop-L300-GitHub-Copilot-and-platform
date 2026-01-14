using Microsoft.AspNetCore.Mvc;
using ZavaStorefront.Services;

namespace ZavaStorefront.Controllers
{
    public class ChatController : Controller
    {
        private readonly ILogger<ChatController> _logger;
        private readonly ChatService _chatService;

        public ChatController(ILogger<ChatController> logger, ChatService chatService)
        {
            _logger = logger;
            _chatService = chatService;
        }

        public IActionResult Index()
        {
            // Initialize conversation history in session if it doesn't exist
            if (HttpContext.Session.GetString("ChatHistory") == null)
            {
                HttpContext.Session.SetString("ChatHistory", string.Empty);
            }

            ViewBag.ChatHistory = HttpContext.Session.GetString("ChatHistory");
            return View();
        }

        [HttpPost]
        public async Task<IActionResult> SendMessage(string userMessage)
        {
            if (string.IsNullOrWhiteSpace(userMessage))
            {
                return RedirectToAction("Index");
            }

            // Get existing chat history
            var chatHistory = HttpContext.Session.GetString("ChatHistory") ?? string.Empty;

            // Add user message to history
            chatHistory += $"You: {userMessage}\n\n";

            // Send message to AI service
            var aiResponse = await _chatService.SendMessageAsync(userMessage);

            // Add AI response to history
            chatHistory += $"AI: {aiResponse}\n\n";

            // Save updated history to session
            HttpContext.Session.SetString("ChatHistory", chatHistory);

            return RedirectToAction("Index");
        }

        [HttpPost]
        public IActionResult ClearChat()
        {
            HttpContext.Session.SetString("ChatHistory", string.Empty);
            return RedirectToAction("Index");
        }
    }
}
