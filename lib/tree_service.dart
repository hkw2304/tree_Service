import 'package:get/get.dart';
import 'package:m_wfm/components/tree/controller/tree_view_controller.dart';
import 'package:m_wfm/models/tree_view/zpma_c0002_model.dart';
import 'package:m_wfm/models/tree_view/zpma_pm7231_model.dart';
import 'package:m_wfm/modules/root/controller/main_controller.dart';
import '../../../../../services/api_service.dart';

enum RfcFunType{
  ZPMA_C0002('ZPMA_C0002');

  const RfcFunType(this.value);
  final String value;
}

class TreeDataService {
  TreeViewController ctr = Get.find<TreeViewController>();

  // 초기 루트 데이터만 로드
  Future<void> onLoadTreeData() async {
    try {
      List<Map<String, ZpmaC0002Model>> c0002_result_mapList = [];

      // 루트 C0002 호출
      Map<String, dynamic>? result_c0002 = await ApiService.fetchZPMAC0002(
          RfcFunType.ZPMA_C0002.value,
          MainController.to.session.value.userId
      );

      for (var jsonItem in result_c0002?['ET_RESULT']) {
        ZpmaC0002Model result_et = ZpmaC0002Model.fromJson(jsonItem);
        Map<String, ZpmaC0002Model> et_map_data = {'ET_RESULT': result_et};
        c0002_result_mapList.add(et_map_data);
      }

      ctr.zpma_c0002_dataList.value = c0002_result_mapList;
      print('루트 데이터 로드 완료: ${c0002_result_mapList.length}개');

    } catch (e) {
      print('루트 데이터 로드 에러: $e');
      throw Exception(e);
    }
  }

  // 첫 번째 레벨 자식 데이터 로드 (부모 클릭 시)
  Future<void> loadFirstLevelChildren(String parentTplnr) async {
    try {
      print('첫 번째 레벨 자식 로드 시작 - Parent TPLNR: $parentTplnr');

      // 이미 로드된 데이터가 있는지 확인
      bool hasExistingData = ctr.zpma_pm7231_dataList.any((item) =>
      item['ET_71640']?.uPPERCD == parentTplnr
      );

      if (hasExistingData) {
        print('첫 번째 레벨 자식 데이터가 이미 존재합니다.');
        return;
      }

      // API 호출하여 첫 번째 레벨 자식 데이터 로드
      List<Map<String, ZpmaPm7231Model>> pm7231_result_mapList =
      await _fetchPm7231DataForParent(parentTplnr);

      // 기존 데이터에 새 데이터 추가
      ctr.zpma_pm7231_dataList.addAll(pm7231_result_mapList);

      print('첫 번째 레벨 자식 로드 완료: ${pm7231_result_mapList.length}개');

    } catch (e) {
      print('첫 번째 레벨 자식 로드 에러: $e');
      throw Exception(e);
    }
  }

  // 설비 데이터 직접 호출 메서드 (FLAG 체크 없음)
  Future<void> fetchPm0494(String parentCode) async {
    try {
      print('설비 데이터 직접 호출 시작 - Parent Code: $parentCode');

      // 이미 해당 parentCode에 대한 설비 데이터가 있는지 확인
      bool hasEquipmentData = ctr.zpma_pm0494_dataList.any((item) =>
      item['ET_RESULT']?.ivTplnr == parentCode
      );

      if (!hasEquipmentData) {
        List<Map<String, ZpmaPm0494Model>> pm0494_result_mapList = await _fetchPm0494(parentCode);
        ctr.zpma_pm0494_dataList.addAll(pm0494_result_mapList);
        print('설비 데이터 직접 로드 완료: ${pm0494_result_mapList.length}개');

        // 로드된 데이터 확인용 출력
        for(var item in pm0494_result_mapList){
          print('설비 아이템: ${item["ET_RESULT"]?.ivEqktx} (EQUNR: ${item["ET_RESULT"]?.ivEqunr})');
        }
      } else {
        print('설비 데이터가 이미 존재합니다 - Parent Code: $parentCode');
      }

    } catch (e) {
      print('설비 데이터 직접 호출 에러: $e');
      throw Exception(e);
    }
  }

  // 두 번째 레벨 자식 데이터 로드
  Future<void> loadSecondLevelChildren(String parentCode) async {
    try {
      print('두 번째 레벨 자식 로드 시작 - Parent Code: $parentCode');

      bool hasExistingData = ctr.zpma_pm7231_dataList_first.any((item) =>
      item['ET_71640']?.uPPERCD == parentCode
      );

      if (hasExistingData) {
        print('두 번째 레벨 자식 데이터가 이미 존재합니다.');
        return;
      }

      var parentItem = ctr.zpma_pm7231_dataList.firstWhere(
              (item) => item['ET_71640']?.cODE == parentCode,
          orElse: () => <String, ZpmaPm7231Model>{}
      );

      if (parentItem.isEmpty) return;

      // FLAG 'X' 체크 제거 - 무조건 자식 데이터 호출
      List<Map<String, ZpmaPm7231Model>> pm7231_result_mapList =
      await _fetchPm7231DataForParent(parentCode);

      ctr.zpma_pm7231_dataList_first.addAll(pm7231_result_mapList);

      print('두 번째 레벨 자식 로드 완료: ${pm7231_result_mapList.length}개');

    } catch (e) {
      print('두 번째 레벨 자식 로드 에러: $e');
      throw Exception(e);
    }
  }

  // 세 번째 레벨 자식 데이터 로드
  Future<void> loadThirdLevelChildren(String parentCode) async {
    try {
      print('세 번째 레벨 자식 로드 시작 - Parent Code: $parentCode');

      bool hasExistingData = ctr.zpma_pm7231_dataList_second.any((item) =>
      item['ET_71640']?.uPPERCD == parentCode
      );

      if (hasExistingData) {
        print('세 번째 레벨 자식 데이터가 이미 존재합니다.');
        return;
      }

      var parentItem = ctr.zpma_pm7231_dataList_first.firstWhere(
              (item) => item['ET_71640']?.cODE == parentCode,
          orElse: () => <String, ZpmaPm7231Model>{}
      );

      if (parentItem.isEmpty) return;

      // FLAG 'X' 체크 제거 - 무조건 자식 데이터 호출
      List<Map<String, ZpmaPm7231Model>> pm7231_result_mapList =
      await _fetchPm7231DataForParent(parentCode);

      ctr.zpma_pm7231_dataList_second.addAll(pm7231_result_mapList);

      print('세 번째 레벨 자식 로드 완료: ${pm7231_result_mapList.length}개');

    } catch (e) {
      print('세 번째 레벨 자식 로드 에러: $e');
      throw Exception(e);
    }
  }

  // 네 번째 레벨 자식 데이터 로드
  Future<void> loadFourthLevelChildren(String parentCode) async {
    try {
      print('네 번째 레벨 자식 로드 시작 - Parent Code: $parentCode');

      bool hasExistingData = ctr.zpma_pm7231_dataList_third.any((item) =>
      item['ET_71640']?.uPPERCD == parentCode
      );

      if (hasExistingData) {
        print('네 번째 레벨 자식 데이터가 이미 존재합니다.');
        return;
      }

      var parentItem = ctr.zpma_pm7231_dataList_second.firstWhere(
              (item) => item['ET_71640']?.cODE == parentCode,
          orElse: () => <String, ZpmaPm7231Model>{}
      );

      if (parentItem.isEmpty) return;

      // FLAG 'X' 체크 제거 - 무조건 자식 데이터 호출
      List<Map<String, ZpmaPm7231Model>> pm7231_result_mapList =
      await _fetchPm7231DataForParent(parentCode);

      ctr.zpma_pm7231_dataList_third.addAll(pm7231_result_mapList);

      print('네 번째 레벨 자식 로드 완료: ${pm7231_result_mapList.length}개');

    } catch (e) {
      print('네 번째 레벨 자식 로드 에러: $e');
      throw Exception(e);
    }
  }

  // 특정 부모에 대한 PM7231 데이터 가져오기
  Future<List<Map<String, ZpmaPm7231Model>>> _fetchPm7231DataForParent(
      String parentCode
      ) async {
    List<Map<String, ZpmaPm7231Model>> pm7231_result_mapList = [];

    Map<String, dynamic>? result_pm7231 = await ApiService.fetchZPMAPM7231(parentCode);

    for (var jsonItem in (result_pm7231?['ET_71640']).skip(1)) {
      ZpmaPm7231Model result_et = ZpmaPm7231Model.fromJson(jsonItem);
      Map<String, ZpmaPm7231Model> et_map_data = {'ET_71640': result_et};
      pm7231_result_mapList.add(et_map_data);
    }

    return pm7231_result_mapList;
  }
}