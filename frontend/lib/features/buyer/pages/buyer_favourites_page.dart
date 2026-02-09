import 'package:flutter/material.dart';
import '../../../shared/styles/app_colors.dart';
import '../data/mock_stores.dart';

class BuyerFavouritesPage extends StatelessWidget {
  final Set<String> favouriteIds;
  final Function(String) onToggleFavourite;

  const BuyerFavouritesPage({
    super.key,
    required this.favouriteIds,
    required this.onToggleFavourite,
  });

  @override
  Widget build(BuildContext context) {
    final favouriteStores = allMockStores
        .where((store) => favouriteIds.contains(store.id))
        .toList();

    return favouriteStores.isEmpty
        ? _buildEmptyState()
        : ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: favouriteStores.length,
            itemBuilder: (context, index) {
              return _buildFavouriteCard(favouriteStores[index]);
            },
          );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_outline,
            size: 80,
            color: AppColors.textLight.withOpacity(0.1),
          ),
          const SizedBox(height: 16),
          Text(
            "Your favourites list is empty",
            style: TextStyle(
              color: AppColors.textLight.withOpacity(0.5),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Heart a place to save it here!",
            style: TextStyle(
              color: AppColors.textLight.withOpacity(0.3),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavouriteCard(MockStore store) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(20),
            ),
            child: Image.network(
              store.image,
              height: 100,
              width: 100,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 100,
                  width: 100,
                  color: AppColors.textLight.withOpacity(0.05),
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 100,
                  width: 100,
                  color: AppColors.textLight.withOpacity(0.05),
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: AppColors.textLight.withOpacity(0.2),
                    size: 24,
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    store.type,
                    style: TextStyle(
                      color: AppColors.textLight.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        store.rating,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        store.price,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: store.isFree
                              ? Colors.green
                              : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: () => onToggleFavourite(store.id),
            icon: const Icon(Icons.favorite, color: Colors.red),
          ),
        ],
      ),
    );
  }
}
