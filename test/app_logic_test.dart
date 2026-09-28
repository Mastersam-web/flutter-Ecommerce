import 'package:firebase_ecommerce/models/checkout_summary.dart';
import 'package:firebase_ecommerce/models/product_model.dart';
import 'package:firebase_ecommerce/providers/cart_provider.dart';
import 'package:firebase_ecommerce/utils/currency_helper.dart';
import 'package:firebase_ecommerce/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/utils/validators.dart';

ProductModel _product({
  String id = 'p1',
  double price = 10000,
  String currency = 'BIF',
  int stock = 5,
  String sellerId = 's1',
}) {
  return ProductModel(
    id: id,
    name: 'Produit $id',
    description: 'Description',
    price: price,
    currency: currency,
    categoryId: 'autres',
    categoryName: 'Autres',
    stock: stock,
    imageUrl: '',
    sellerId: sellerId,
    sellerName: 'Vendeur',
    sellerWhatsapp: '+25779123456',
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('CurrencyHelper', () {
    test('convertit BIF <-> USD <-> EUR avec les taux documentés', () {
      expect(CurrencyHelper.fromBIF(2850, 'USD'), closeTo(1.0, 1e-9));
      expect(CurrencyHelper.fromBIF(3100, 'EUR'), closeTo(1.0, 1e-9));
      expect(CurrencyHelper.toBIF(2, 'USD'), closeTo(5700, 1e-9));
      expect(
        CurrencyHelper.convert(1, from: 'EUR', to: 'USD'),
        closeTo(3100 / 2850, 1e-9),
      );
    });

    test('les frais de livraison sont convertis dans la devise choisie', () {
      expect(CurrencyHelper.deliveryFee('BIF'), 5000);
      expect(CurrencyHelper.deliveryFee('USD'), 1.75);
    });
  });

  group('CartProvider', () {
    test('ajoute, augmente et limite la quantité au stock', () {
      final cart = CartProvider();
      final product = _product(stock: 3);

      expect(cart.addToCart(product, quantity: 2), CartAddResult.added);
      expect(cart.itemCount, 2);
      expect(cart.increaseQuantity('p1'), isTrue);
      expect(cart.increaseQuantity('p1'), isFalse); // stock max atteint
      expect(cart.itemCount, 3);
    });

    test('refuse un produit en rupture et un autre vendeur', () {
      final cart = CartProvider();
      expect(cart.addToCart(_product(stock: 0)), CartAddResult.outOfStock);

      cart.addToCart(_product());
      expect(
        cart.addToCart(_product(id: 'p2', sellerId: 's2')),
        CartAddResult.otherSeller,
      );
    });

    test('diminuer à 1 retire le produit', () {
      final cart = CartProvider();
      cart.addToCart(_product());
      cart.decreaseQuantity('p1');
      expect(cart.isEmpty, isTrue);
    });

    test('synchronisation : produit supprimé retiré, stock réduit ajusté', () {
      final cart = CartProvider();
      cart.addToCart(_product(id: 'a', stock: 5), quantity: 4);
      cart.addToCart(_product(id: 'b', stock: 5), quantity: 1);

      final messages = cart.syncWithProducts([_product(id: 'a', stock: 2)]);

      expect(messages.length, 2);
      expect(cart.items.length, 1);
      expect(cart.items.first.quantity, 2);
    });
  });

  group('CheckoutSummary', () {
    test('retrait en boutique : aucun frais de livraison', () {
      final cart = CartProvider()..addToCart(_product(), quantity: 2);
      final summary = CheckoutSummary.fromCart(
        cart: cart.items,
        currency: 'BIF',
        isDelivery: false,
      );

      expect(summary.subtotal, 20000);
      expect(summary.deliveryFee, 0);
      expect(summary.total, 20000);
    });

    test('livraison : frais ajoutés au total, en USD', () {
      final cart = CartProvider()
        ..addToCart(_product(price: 10, currency: 'USD'), quantity: 2);
      final summary = CheckoutSummary.fromCart(
        cart: cart.items,
        currency: 'USD',
        isDelivery: true,
      );

      expect(summary.subtotal, 20);
      expect(summary.deliveryFee, 1.75);
      expect(summary.total, 21.75);
    });
  });

  group('Validators', () {
    test('prix invalide', () {
      expect(Validators.price(''), isNotNull);
      expect(Validators.price('abc'), isNotNull);
      expect(Validators.price('0'), isNotNull);
      expect(Validators.price('-5'), isNotNull);
      expect(Validators.price('1500,50'), isNull);
    });

    test('stock négatif ou invalide', () {
      expect(Validators.stock('-1'), isNotNull);
      expect(Validators.stock('2.5'), isNotNull);
      expect(Validators.stock('0'), isNull);
      expect(Validators.stock('12'), isNull);
    });

    test('numéro WhatsApp au format international', () {
      expect(Validators.whatsapp('79123456'), isNotNull);
      expect(Validators.whatsapp('+257 79 12 34 56'), isNull);
    });
  });
}
