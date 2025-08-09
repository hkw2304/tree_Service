import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:m_wfm/common/common.dart';
import 'package:m_wfm/modules/standard_info/contorller/standard_info_tree_controller.dart';
import 'package:m_wfm/utils/ui.dart';
import 'package:m_wfm/components/tree_view/widget/custom_expansion_tile.dart';
import 'package:m_wfm/modules/standard_info/tree/standard_info_tree_service.dart';

/// 기준정보 트리 페이지 (무제한 depth 확장 가능, 마지막 depth 마스코트 표시)
class StandardInfoTree extends StatefulWidget {
  const StandardInfoTree({super.key});

  @override
  State<StandardInfoTree> createState() => _StandardInfoTreeState();
}

class _StandardInfoTreeState extends State<StandardInfoTree> {
  final StandardInfoTreeService treeDataService = StandardInfoTreeService();
  final controller = StandardInfoTreeController.to;

  final int maxDepth = 5; // 원하는 최대 depth

  @override
  void initState() {
    super.initState();
    treeDataService.loadStandardInfoData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Obx(() {
            // 루트: LEVEL == '01'
            final roots = controller.zpmb_pm0010_dataList
                .where((e) => e.level == '01')
                .toList();

            return Column(
              children: roots.map((item) {
                return _TreeNode(
                  item: item,
                  depth: 0,
                  maxDepth: maxDepth,
                );
              }).toList(),
            );
          }),
        ),
      ),
    );
  }
}

/// 개별 트리 노드 위젯 (재귀적으로 자기 자신을 호출)
class _TreeNode extends StatefulWidget {
  final dynamic item;
  final int depth;
  final int maxDepth;

  const _TreeNode({
    required this.item,
    required this.depth,
    required this.maxDepth,
  });

  @override
  State<_TreeNode> createState() => _TreeNodeState();
}

class _TreeNodeState extends State<_TreeNode> {
  bool _isLoaded = false;
  bool _isLoading = false;
  List<dynamic> _childrenData = [];

  final controller = StandardInfoTreeController.to;

  @override
  Widget build(BuildContext context) {
    // 마지막 depth일 경우: 마스코트 표시
    if (widget.depth >= widget.maxDepth) {
      return _buildMascotPlaceholder();
    }

    // 자식이 없고 이미 로딩이 끝난 경우: ListTile
    if (_childrenData.isEmpty && _isLoaded) {
      return ListTile(
        title: Text(widget.item.text ?? ''),
        onTap: () => print('선택: ${widget.item.code}'),
      );
    }

    return CustomExpansionTile(
      title: widget.item.text ?? '',
      depth: widget.depth,
      isLastChild: false,
      children: _isLoading
          ? [Ui.loadingIndicator()]
          : _isLoaded
          ? _childrenData
          .map((child) => _TreeNode(
        item: child,
        depth: widget.depth + 1,
        maxDepth: widget.maxDepth,
      ))
          .toList()
          : [],
      onExpansionChanged: (isExpanded) async {
        if (isExpanded && !_isLoaded && !_isLoading) {
          await _loadChildren();
        }
      },
    );
  }

  /// 자식 데이터 로드
  Future<void> _loadChildren() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 실제 API 호출 로직 연결 가능 (여기서는 2초 지연 시뮬레이션)
      await Future.delayed(const Duration(seconds: 2));
      _childrenData = _findChildren(widget.item, widget.depth);
      _isLoaded = true;
    } catch (e) {
      print('자식 로딩 에러: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 부모 item과 depth 기반으로 자식 찾기
  List<dynamic> _findChildren(dynamic parent, int depth) {
    final all = controller.zpmb_pm0010_dataList;
    final parentCode = parent.code ?? '';
    final nextLevel = '0${depth + 2}'; // depth 0 → level 02

    return all
        .where((node) =>
    node.level == nextLevel &&
        node.code.startsWith(parentCode) &&
        node.code != parentCode)
        .toList();
  }

  /// 마지막 depth일 때 표시할 마스코트 & 문구
  Widget _buildMascotPlaceholder() {
    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(vertical: 24.h),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/img_kwater_mascot.png',
            width: 100.w,
            height: 100.h,
          ),
          SizedBox(height: 16.h),
          Text(
            '아직 준비중입니다.',
            style: TextStyle(
              fontSize: 22.sp,
              color: Common.hexToColor('#424242'),
            ),
          ),
        ],
      ),
    );
  }
}
