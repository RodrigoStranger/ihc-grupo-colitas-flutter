import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../core/strings.dart';
import '../viewmodels/firma_viewmodel.dart';
import 'firma_detalle_screen.dart';

class CampanasScreen extends StatefulWidget {
  const CampanasScreen({super.key});

  @override
  State<CampanasScreen> createState() => _CampanasScreenState();
}

class _CampanasScreenState extends State<CampanasScreen> {
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent * 0.8) {
      final viewModel = context.read<FirmaViewModel>();
      if (!viewModel.isLoading && !viewModel.isLoadingMore) {
        viewModel.loadMoreFirmas();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FirmaViewModel(),
      child: Scaffold(
        backgroundColor: lightPastelBlue,
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            menuCampanasTitle,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: accentBlue,
          elevation: 0,
        ),
        body: Consumer<FirmaViewModel>(
          builder: (context, viewModel, _) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!viewModel.isLoading && viewModel.firmas.isEmpty) {
                viewModel.fetchFirmas();
              }
            });

            if (viewModel.isLoading && viewModel.firmas.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(
                  color: accentBlue,
                ),
              );
            }
            
            if (viewModel.error != null && viewModel.firmas.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${viewModel.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: viewModel.fetchFirmas,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            }
            
            final firmas = viewModel.firmas;
            
            if (firmas.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(campanasNoRegistradas),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: viewModel.fetchFirmas,
                      child: const Text('Recargar'),
                    ),
                  ],
                ),
              );
            }
            
            return RefreshIndicator(
              onRefresh: viewModel.fetchFirmas,
              color: accentBlue,
              child: ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                itemCount: firmas.length + (viewModel.isLoadingMore ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index >= firmas.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: accentBlue,
                        ),
                      ),
                    );
                  }
                  final firma = firmas[index];
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FirmaDetalleScreen(firma: firma),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1), // ignore: deprecated_member_use
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            margin: const EdgeInsets.only(right: 16),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Icon(
                              Icons.edit_document,
                              size: 32,
                              color: Colors.blue,
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  firma.nombreFirma,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '$campanasMotivoLabel${firma.motivoFirma}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '$campanasFechaLabel${firma.fechaRegistro.toLocal().toString().split(' ')[0]}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
