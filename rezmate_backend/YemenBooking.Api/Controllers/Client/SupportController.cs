using MediatR;
using Microsoft.AspNetCore.Mvc;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Support.Commands.SendSupportMessage;

namespace YemenBooking.Api.Controllers.Client
{
    /// <summary>
    /// كونترولر الدعم والمساعدة للعملاء
    /// Client Support Controller
    /// </summary>
    public class SupportController : BaseClientController
    {
        public SupportController(IMediator mediator) : base(mediator)
        {
        }

        /// <summary>
        /// إرسال رسالة دعم
        /// Send support message
        /// </summary>
        /// <param name="command">بيانات رسالة الدعم</param>
        /// <returns>نتيجة الإرسال</returns>
        [HttpPost("send")]
        public async Task<ActionResult<ResultDto<SendSupportMessageResponse>>> SendSupportMessage(
            [FromBody] SendSupportMessageCommand command)
        {
            var result = await _mediator.Send(command);
            return Ok(result);
        }
    }
}
