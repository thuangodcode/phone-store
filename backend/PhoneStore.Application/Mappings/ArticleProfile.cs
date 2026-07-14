using AutoMapper;
using PhoneStore.Application.DTOs.Article;
using PhoneStore.Domain.Entities;

namespace PhoneStore.Application.Mappings;

public class ArticleProfile : Profile
{
    public ArticleProfile()
    {
        CreateMap<Article, ArticleDto>();
        CreateMap<CreateArticleDto, Article>();
        CreateMap<UpdateArticleDto, Article>();
    }
}

