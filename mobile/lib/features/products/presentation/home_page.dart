import 'package:flutter/material.dart';
import 'widgets/banner_carousel.dart';
import 'widgets/brand_selector.dart';
import 'widgets/product_grid.dart';
import 'widgets/floating_chat_buttons.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _selectedBrandId = '';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030712), // --color-background = gray-950 (Dark Mode sâu)
      body: Stack(
        children: [
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Custom AppBar sliver
                SliverAppBar(
                  backgroundColor: const Color(0xFF030712),
                  floating: true,
                  pinned: true,
                  elevation: 0,
                  title: Row(
                    children: [
                      RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: 'Phone',
                              style: TextStyle(
                                color: Color(0xFFF9FAFB),
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            TextSpan(
                              text: 'Store',
                              style: TextStyle(
                                color: Color(0xFFEF4444),
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(
                        Icons.notifications_none_outlined,
                        color: Color(0xFFF9FAFB),
                      ),
                      onPressed: () {},
                    ),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.shopping_bag_outlined,
                            color: Color(0xFFF9FAFB),
                          ),
                          onPressed: () {},
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF030712),
                                width: 1,
                              ),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 14,
                              minHeight: 14,
                            ),
                            child: const Text(
                              '3',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(width: 8),
                  ],
                  // Search Box
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(60),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF111827),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF1F2937),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.search,
                              color: Color(0xFF6B7280),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                style: const TextStyle(
                                  color: Color(0xFFF9FAFB),
                                  fontSize: 14,
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _searchQuery = value;
                                  });
                                },
                                decoration: const InputDecoration(
                                  hintText: 'Bạn cần tìm điện thoại gì hôm nay?',
                                  hintStyle: TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontSize: 13,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                            if (_searchQuery.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.clear, color: Color(0xFF6B7280), size: 16),
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                    _searchQuery = '';
                                  });
                                },
                              ),
                            IconButton(
                              icon: const Icon(
                                Icons.tune,
                                color: Color(0xFFEF4444),
                                size: 18,
                              ),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Section 1: Promotion Banner Carousel
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: BannerCarousel(),
                  ),
                ),

                // Section 2: Brands Title & List Selector
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Hãng Sản Xuất',
                              style: TextStyle(
                                color: Color(0xFFF9FAFB),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              'Xem tất cả',
                              style: TextStyle(
                                color: Color(0xFFEF4444),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      BrandSelector(
                        onBrandSelected: (brandId, brandName) {
                          setState(() {
                            _selectedBrandId = brandId;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                // Section 3: Hot Products Title
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sản Phẩm Nổi Bật',
                          style: TextStyle(
                            color: Color(0xFFF9FAFB),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Color(0xFF6B7280),
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ),

                // Grid View of Products
                SliverToBoxAdapter(
                  child: ProductGrid(
                    brandId: _selectedBrandId,
                    searchQuery: _searchQuery,
                  ),
                ),
                
                // Bottom padding to avoid buttons overlap content
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            ),
          ),
          // Section 4: Floating Chat Actions (AI Assistant & Live Chat)
          const FloatingChatButtons(),
        ],
      ),
    );
  }
}
