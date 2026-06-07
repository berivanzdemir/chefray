import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../models/product/product_model.dart';

class OpenFoodFactsService {
  static const String _baseUrl = 'https://world.openfoodfacts.org/api/v2/product';
  static const String _userAgent = 'ChefRay/1.0 (contact: pythonflg@gmail.com)';

  Future<ProductModel?> getProductByBarcode(String barcode) async {
    try {
      if (kDebugMode) {
        print('API request URL: $_baseUrl/$barcode.json');
      }

      final url = Uri.parse('$_baseUrl/$barcode.json');
      final response = await http.get(url, headers: {
        'User-Agent': _userAgent,
      }).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        
        final status = jsonResponse['status'];
        if (status != 1) {
          if (kDebugMode) {
            print('Product found: false (Status: $status)');
          }
          return null; // Product not found
        }

        if (kDebugMode) {
          print('Product found: true');
          print('Parsed product name: ${jsonResponse['product']?['product_name']}');
        }

        return ProductModel.fromJson(jsonResponse, barcode);
      } else {
        if (kDebugMode) {
          print('API error: Status Code ${response.statusCode}');
        }
        throw HttpException('Open Food Facts API hatası: ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      if (kDebugMode) {
        print('API error: Timeout - $e');
      }
      throw Exception('İstek zaman aşımına uğradı. İnternet bağlantınızı kontrol edin.');
    } catch (e) {
      if (kDebugMode) {
        print('API error: $e');
      }
      throw Exception('Ürün bilgisi alınırken bir sorun oluştu. Lütfen tekrar deneyin.');
    }
  }
}
