using Microsoft.EntityFrameworkCore;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Infrastructure.Data.Context;

namespace YemenBooking.Infrastructure.Repositories;

/// <summary>
/// تنفيذ مستودع سياسات العقار
/// Property policy repository implementation
/// </summary>
public class PropertyPolicyRepository : BaseRepository<PropertyPolicy>, IPropertyPolicyRepository
{
    /// <summary>
    /// منشئ مستودع سياسات العقار
    /// Constructor for property policy repository
    /// </summary>
    /// <param name="context">سياق قاعدة البيانات</param>
    public PropertyPolicyRepository(YemenBookingDbContext context) : base(context)
    {
    }

    /// <summary>
    /// الحصول على سياسات العقار حسب معرف العقار
    /// Get property policies by property ID
    /// </summary>
    public async Task<IEnumerable<PropertyPolicy>> GetByPropertyIdAsync(Guid propertyId, CancellationToken cancellationToken = default)
    {
        return await _context.PropertyPolicies
            .AsNoTracking()
            .Where(pp => pp.PropertyId == propertyId)
            .OrderBy(pp => pp.Type)
            .ToListAsync(cancellationToken);
    }

    /// <summary>
    /// الحصول على سياسة العقار حسب المعرف
    /// Get property policy by ID
    /// </summary>
    public async Task<PropertyPolicy?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        return await _context.PropertyPolicies
            .AsNoTracking()
            .FirstOrDefaultAsync(pp => pp.Id == id, cancellationToken);
    }

    /// <summary>
    /// إنشاء سياسة عقار جديدة
    /// Create new property policy
    /// </summary>
    public async Task<PropertyPolicy> CreateAsync(PropertyPolicy propertyPolicy, CancellationToken cancellationToken = default)
    {
        await _context.PropertyPolicies.AddAsync(propertyPolicy, cancellationToken);
        await _context.SaveChangesAsync(cancellationToken);
        return propertyPolicy;
    }

    /// <summary>
    /// تحديث سياسة العقار
    /// Update property policy
    /// </summary>
    public async Task<PropertyPolicy> UpdateAsync(PropertyPolicy propertyPolicy, CancellationToken cancellationToken = default)
    {
        _context.PropertyPolicies.Update(propertyPolicy);
        await _context.SaveChangesAsync(cancellationToken);
        return propertyPolicy;
    }

    /// <summary>
    /// حذف سياسة العقار
    /// Delete property policy
    /// </summary>
    public async Task<bool> DeleteAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var policy = await GetByIdAsync(id, cancellationToken);
        if (policy == null)
            return false;

        _context.PropertyPolicies.Remove(policy);
        await _context.SaveChangesAsync(cancellationToken);
        return true;
    }

    /// <summary>
    /// الحصول على سياسات العقار حسب النوع
    /// Get property policies by type
    /// </summary>
    public async Task<IEnumerable<PropertyPolicy>> GetByPropertyIdAndTypeAsync(
        Guid propertyId, 
        string policyType, 
        CancellationToken cancellationToken = default)
    {
        return await _context.PropertyPolicies
            .AsNoTracking()
            .Where(pp => pp.PropertyId == propertyId && pp.Type.ToString() == policyType)
            .ToListAsync(cancellationToken);
    }
}
