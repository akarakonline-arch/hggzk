using YemenBooking.Core.Entities;

namespace YemenBooking.Core.Interfaces.Repositories;

public interface IUserWalletAccountRepository : IRepository<UserWalletAccount>
{
    Task<List<UserWalletAccount>> GetByUserIdAsync(Guid userId, CancellationToken cancellationToken = default);

    Task<List<UserWalletAccount>> ReplaceForUserAsync(Guid userId, List<UserWalletAccount> accounts, CancellationToken cancellationToken = default);
}
