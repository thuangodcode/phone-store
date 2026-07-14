using AutoMapper;
using PhoneStore.Application.DTOs.Chat;
using PhoneStore.Domain.Entities;

namespace PhoneStore.Application.Mappings;

public class ChatProfile : Profile
{
    public ChatProfile()
    {
        CreateMap<ChatMessage, ChatMessageDto>();
        CreateMap<ChatSession, ChatSessionDto>();
    }
}

