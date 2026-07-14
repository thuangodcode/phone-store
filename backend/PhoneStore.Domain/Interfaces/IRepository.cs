using System.Linq.Expressions;

namespace PhoneStore.Domain.Interfaces;

public interface IRepository<T> where T : class
{
    Task<IEnumerable<T>> GetAllAsync();
    Task<T?> GetByIdAsync(string id);
    Task<IEnumerable<T>> FindAsync(Expression<Func<T, bool>> predicate);
    Task<T?> FindOneAsync(Expression<Func<T, bool>> predicate);
    Task CreateAsync(T entity);
    Task UpdateAsync(string id, T entity);
    Task DeleteAsync(string id);
    Task<long> CountAsync(Expression<Func<T, bool>>? predicate = null);
}
