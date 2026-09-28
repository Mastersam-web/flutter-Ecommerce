# 🛍️ Boutique Firebase — Flutter + Firebase

Application e-commerce **Flutter** (Web / Android / iOS) connectée à **Firebase** :
Authentication, Cloud Firestore et Storage. Deux espaces : **visiteur/client** et **vendeur**.

---

## 🚀 Démarrage en 6 étapes

> ⚠️ **Sans l'étape 2, l'application affiche un écran « Firebase n'est pas encore configuré »**
> (c'était la cause de l'écran blanc : les valeurs Firebase étaient encore des exemples).

### 1. Créer le projet Firebase
[console.firebase.google.com](https://console.firebase.google.com) → *Ajouter un projet*.

### 2. Renseigner la configuration (`lib/firebase_options.dart`)
**Option A (recommandée)** : dans un terminal, à la racine du projet
```bash
dart pub global activate flutterfire_cli
flutterfire configure
```
Choisissez votre projet, cochez **Android** (et iOS si besoin) : le fichier est généré tout seul.

**Option B (manuelle, Android)** : Console Firebase → ⚙ *Paramètres du projet* → *Vos applications* →
**Ajouter une application Android** avec le nom de package **`com.example.firebase_ecommerce`**
(SHA-1 non nécessaire pour l'e-mail/mot de passe). Copiez `apiKey`, `appId`, `messagingSenderId`,
`projectId`, `storageBucket` dans la section `android` de `lib/firebase_options.dart`.
Pour iOS : bundle `com.example.firebaseEcommerce`.

> Pas besoin de `google-services.json` : la configuration passe par `firebase_options.dart`.

### 3. Activer les services
* **Authentication** → *Sign-in method* → activer **Adresse e-mail/Mot de passe**.
* **Firestore Database** → *Créer une base* (mode production).
* **Storage** → *Commencer* (facultatif, voir « Images » plus bas).

### 4. Publier les règles de sécurité
* Firestore → onglet **Règles** → coller le contenu de `firestore.rules` → **Publier**.
* Storage → onglet **Règles** → coller `storage.rules` → **Publier**.

### 5. Lancer sur un téléphone Android
**Téléphone réel (recommandé, surtout pour tester WhatsApp)** : activez *Options pour les développeurs* →
*Débogage USB*, branchez le téléphone en USB et acceptez l'autorisation.
**Ou émulateur** : Android Studio → *Device Manager* → créer un appareil (image *Google Play*).
```bash
flutter pub get
flutter devices          # vérifier que le téléphone / l'émulateur apparaît
flutter run              # lance sur l'appareil Android
```
Installer un APK sur le téléphone :
```bash
flutter build apk --release
# fichier : build/app/outputs/flutter-apk/app-release.apk
```
Après avoir modifié `firebase_options.dart`, **arrêtez complètement** l'application puis relancez-la.

*(Le navigateur reste possible avec `flutter run -d chrome`, mais ce n'est pas nécessaire.)*

---

## 🖼️ Images des produits
* Envoi vers **Firebase Storage** (`products/{sellerId}/{uuid}.jpg`), l'URL est stockée dans Firestore.
* Fonctionne sur Web **et** mobile (envoi d'octets, plus de `dart:io File`).
* **Mode secours automatique** : si Storage est indisponible (projet sans plan Blaze, règles non publiées, hors-ligne…),
  l'image (≤ 600 Ko, déjà compressée) est enregistrée en base64 dans le document Firestore du produit.
  Le produit reste persistant et visible ; un message l'indique au vendeur.

## 💱 Taux de change utilisés (documentés, simulés)
| Devise | Valeur en BIF |
|--------|---------------|
| BIF    | 1 BIF = 1 BIF |
| USD    | **1 USD = 2 850 BIF** |
| EUR    | **1 EUR = 3 100 BIF** |

Frais de livraison fixes : **5 000 BIF** (converti dans la devise choisie : ≈ 1,75 USD / 1,61 EUR).
Modifiables dans `lib/utils/constants.dart`. Le taux utilisé est enregistré dans chaque commande (`exchangeRate`).

---

## 🗄️ Structure Firestore
```
users/{uid}         name, email, phone, role (client|seller), whatsappNumber, createdAt
categories/{id}     name, description
products/{id}       name, description, price, currency, categoryId, categoryName, stock,
                    imageUrl, sellerId, sellerName, sellerWhatsapp, createdAt, updatedAt
orders/{ORD-…}      clientId, clientName, clientPhone, clientEmail,
                    sellerId, sellerName, sellerWhatsapp,
                    items[{productId, productName, unitPrice, quantity}],
                    subtotal, deliveryFee, total, currency, exchangeRate,
                    deliveryOption (delivery|pickup), deliveryLocation,
                    paymentMethod (mobile_money|bank_card), paymentStatus, paymentReference,
                    orderStatus, createdAt
```
Aucune requête n'utilise `where + orderBy` : **aucun index composite** à créer (tri fait dans l'application).

## 🔐 Sécurité (`firestore.rules`)
| Exigence | Règle |
|---|---|
| Lecture publique du catalogue | `products` : `read: if true` |
| Seul un vendeur crée un produit | `create` : rôle `seller` + `sellerId == auth.uid` + champs valides (prix > 0, stock ≥ 0) |
| Un vendeur ne modifie/supprime que ses produits | `update/delete` : `resource.data.sellerId == auth.uid` |
| Client crée ses commandes | `orders.create` : rôle `client` + `clientId == auth.uid` |
| Client lit ses commandes / vendeur les siennes | `read` : `clientId` ou `sellerId == auth.uid` |
| Vendeur : statut seulement | `orders.update` : `affectedKeys().hasOnly(['orderStatus'])` |
| Profils protégés | `users` : lecture/écriture de son propre document, **rôle non modifiable** |
| Achat → stock | un client ne peut que **diminuer** le champ `stock` d'un produit |

> Limite connue : la baisse de stock est faite depuis l'application (transaction Firestore). En production,
> on utiliserait une Cloud Function pour empêcher tout abus.

---

## ✅ Correspondance avec le cahier des charges

| Exigence | Où / comment |
|---|---|
| Visiteur : parcourir, détails, recherche, filtre, catégories | `HomeScreen`, `ProductDetailScreen` (sans compte) |
| Action protégée → redirection vers l'authentification | `ensureClientAuthenticated()` (`utils/auth_guard.dart`) |
| Inscription/connexion Client & Vendeur, WhatsApp obligatoire vendeur | `RegisterScreen`, `LoginScreen`, `AuthService` |
| Profil stocké dans Firestore, rôle → fonctionnalités | `users/{uid}`, `RootGate` |
| Vendeur : créer / voir / modifier / supprimer / stock | `ProductFormScreen`, `MyProductsScreen` |
| Produit visible publiquement après création | catalogue en temps réel (`ProductProvider`) |
| Chargement, liste vide, erreurs Firebase, produit indisponible | `EmptyState`, `ErrorState`, `ProductDetailScreen` |
| Panier : ajout, +/-, suppression, sous-total, stock | `CartProvider`, `CartScreen` |
| Interdiction de dépasser le stock | panier + transaction Firestore à la commande |
| 3 devises + taux documentés | BIF / USD / EUR, voir tableau ci-dessus |
| Checkout complet | `CheckoutScreen` (produits, quantités, prix, sous-totaux, devise, mode, frais, total) |
| Livraison (adresse + téléphone + frais) / Boutique (0 frais) | `CheckoutScreen` |
| Paiement simulé (2 méthodes, succès/échec) | `PaymentScreen` (interrupteur « Simuler un paiement échoué ») |
| Commande dans Firestore + paiement associé | `OrderService.placeOrder` (transaction : commande + stock) |
| Historique / détail des commandes client | `OrderHistoryScreen`, `OrderDetailScreen` |
| Commandes reçues par le vendeur | `SellerOrdersScreen` (+ changement de statut) |
| WhatsApp + gestion « non installé » sans crash | `WhatsAppService`, `WhatsAppOrderButton` |
| Règles de sécurité | `firestore.rules`, `storage.rules` |
| Bonus | tri, statuts de commande, statistiques vendeur |

**Choix de conception** : un panier ne contient que les produits d'**un seul vendeur** (la commande est
envoyée à un seul vendeur, comme dans le modèle `sellerId` du cahier des charges). Ajouter un produit d'un
autre vendeur propose de vider le panier.

---

## 🎬 Scénario de démonstration

**Vendeur** : *S'inscrire* (Vendeur, WhatsApp `+257…`) → *Créer un produit* (image, prix, stock, catégorie)
→ ouvrir le catalogue public pour le voir → *Mes produits → Modifier* → vérifier → *Commandes reçues*.

**Client** : *Se déconnecter* → parcourir sans compte → *Ajouter au panier* (redirection connexion) →
s'inscrire comme Client → panier (±, devise) → *Passer la commande* → **Livraison** + adresse → *Continuer* →
payer (Mobile Money / Carte) → confirmation → *Mes commandes* → **Envoyer via WhatsApp**.

**Boutique** : refaire une commande avec *Retrait en boutique* → « Aucun frais de livraison », total sans frais.

### Cas d'erreur démontrables (≥ 5 demandés)
1. Identifiants incorrects (connexion) · 2. Champs d'inscription vides · 3. Prix invalide (`abc`, `0`, `-5`)
· 4. Stock négatif · 5. Produit en rupture · 6. Quantité > stock (bouton « + » bloqué + message)
· 7. Adresse de livraison manquante · 8. Paiement échoué · 9. Panier vide · 10. Accès protégé sans connexion
· 11. WhatsApp indisponible (message + copie du texte) · 12. Réseau/Firebase (bouton *Réessayer*).

---

## 🧪 Tests
```bash
flutter test
```
Tests unitaires : conversion de devises, panier (stock, vendeur unique, synchronisation), calcul du total
(livraison / retrait), validateurs.

## 📁 Organisation du code
```
lib/
├── main.dart · firebase_options.dart
├── models/      user, product, category, cart_item, order, checkout_summary
├── providers/   auth, product, cart, currency          (Provider / ChangeNotifier)
├── services/    auth, product, order, storage, whatsapp (Firebase & WhatsApp)
├── utils/       constants, currency_helper, validators, helpers, labels, auth_guard…
├── widgets/     app_image, product_card, whatsapp_button, option_tile…
└── screens/     auth/  client/  seller/  common/
```
