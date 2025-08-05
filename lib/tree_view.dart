import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:m_wfm/components/tree/controller/tree_view_controller.dart';
import 'package:m_wfm/components/tree/service/tree_data_service.dart';
import 'package:m_wfm/components/tree/widget/custom_expansion_tile.dart';

class DataTree extends StatefulWidget {
  DataTree({super.key});

  @override
  State<DataTree> createState() => _DataTreeViewState();
}

class _DataTreeViewState extends State<DataTree> {
  TreeDataService tree_data_service = TreeDataService();

  @override
  void initState() {
    super.initState();
    if(TreeViewController.to.zpma_c0002_dataList.isEmpty)
      tree_data_service.onLoadTreeData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Obx(
              () => SingleChildScrollView(
            child: Column(
              children: TreeViewController.to.zpma_c0002_dataList
                  .map((root_item) => Container(
                child: DynamicCustomExpansionTile(
                  title: '${root_item['ET_RESULT']?.pLTXT}',
                  tplnr: '${root_item['ET_RESULT']?.tPLNR}',
                  depth: 0,
                  rootItem: root_item,
                  treeDataService: tree_data_service,
                ),
              ))
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}

// 동적 로딩을 지원하는 CustomExpansionTile 래퍼
class DynamicCustomExpansionTile extends StatefulWidget {
  final String title;
  final String tplnr;
  final int depth;
  final dynamic rootItem;
  final dynamic parentItem;
  final TreeDataService treeDataService;

  const DynamicCustomExpansionTile({
    super.key,
    required this.title,
    required this.tplnr,
    required this.depth,
    required this.treeDataService,
    this.rootItem,
    this.parentItem,
  });

  @override
  State<DynamicCustomExpansionTile> createState() => _DynamicCustomExpansionTileState();
}

class _DynamicCustomExpansionTileState extends State<DynamicCustomExpansionTile> {
  List<Widget>? _children;
  bool _isLoaded = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    // depth 4 이상이면 확장 불가능한 텍스트만 표시
    if (widget.depth >= 4) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Row(
          children: [
            Icon(Icons.description, size: 16, color: Colors.grey[600]),
            SizedBox(width: 8),
            Text(
              '${widget.tplnr} ${widget.title}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      );
    }

    return CustomExpansionTile(
      title: widget.title,
      tplnr: widget.tplnr,
      depth: widget.depth,
      children: _isLoading ? [_buildLoadingWidget()] : _buildChildrenWithObx(),
      onExpansionChanged: (isExpanded) async {
        if (isExpanded && !_isLoaded && !_isLoading) {
          await _loadChildren();
        }
      },
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      padding: EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text('로딩 중...', style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  List<Widget>? _buildChildrenWithObx() {
    if (!_isLoaded) return _children;

    return [
      Obx(() {
        return Column(
          children: _getChildrenWidgets(),
        );
      })
    ];
  }

  Future<void> _loadChildren() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('${widget.depth} depth 자식 로딩 시작: ${widget.tplnr}');

      if (widget.depth == 0) {
        // 루트 아이템 클릭 - 첫 번째 레벨 로드
        await widget.treeDataService.loadFirstLevelChildren(widget.tplnr);
      } else if (widget.depth == 1) {
        // 첫 번째 레벨 클릭 - 두 번째 레벨 로드
        await widget.treeDataService.loadSecondLevelChildren(widget.tplnr);
      } else if (widget.depth == 2) {
        // 두 번째 레벨 클릭 - 세 번째 레벨 로드
        await widget.treeDataService.loadThirdLevelChildren(widget.tplnr);
      } else if (widget.depth == 3) {
        // 세 번째 레벨 클릭 - 네 번째 레벨 로드
        await widget.treeDataService.loadFourthLevelChildren(widget.tplnr);
      }

      setState(() {
        _isLoaded = true;
        _isLoading = false;
      });

    } catch (e) {
      print('자식 로딩 에러: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Widget> _getChildrenWidgets() {
    if (widget.depth == 0) {
      // 루트 아이템의 자식들 (첫 번째 레벨)
      return TreeViewController.to.zpma_pm7231_dataList
          .where((parent_item) =>
      parent_item['ET_71640']?.uPPERCD == widget.rootItem['ET_RESULT']?.tPLNR)
          .map((parent_item) => _buildChildWidget(parent_item, 1))
          .toList();
    } else if (widget.depth == 1) {
      // 첫 번째 레벨의 자식들 (두 번째 레벨)
      return TreeViewController.to.zpma_pm7231_dataList_first
          .where((first_child) =>
      first_child['ET_71640']?.uPPERCD == widget.parentItem['ET_71640']?.cODE)
          .map((first_child) => _buildChildWidget(first_child, 2))
          .toList();
    } else if (widget.depth == 2) {
      // 두 번째 레벨의 자식들 (세 번째 레벨)
      return TreeViewController.to.zpma_pm7231_dataList_second
          .where((second_child) =>
      second_child['ET_71640']?.uPPERCD == widget.parentItem['ET_71640']?.cODE)
          .map((second_child) => _buildChildWidget(second_child, 3))
          .toList();
    } else if (widget.depth == 3) {
      // 세 번째 레벨의 자식들 (네 번째 레벨) - 다른 depth와 동일하게 처리
      return TreeViewController.to.zpma_pm7231_dataList_third
          .where((third_child) =>
      third_child['ET_71640']?.uPPERCD == widget.parentItem['ET_71640']?.cODE)
          .map((third_child) => _buildChildWidget(third_child, 4))
          .toList();
    }

    return [];
  }

  // FLAG에 따라 ExpansionTile 또는 InkWell 생성
  Widget _buildChildWidget(dynamic childItem, int childDepth) {
    String? flag = childItem['ET_71640']?.fLAG;
    String title = childItem['ET_71640']?.tEXT ?? '';
    String code = childItem['ET_71640']?.cODE ?? '';

    // FLAG가 'X'이면 InkWell (0494 호출 버튼)
    if (flag == 'X') {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: InkWell(
          onTap: () async {
            print('FLAG X 클릭 - 0494 호출: $code');
            try {
              await widget.treeDataService.fetchPm0494(code);
              // TODO: 설비 목록 페이지로 이동하거나 데이터 표시
              print('0494 호출 완료 - 설비 데이터 화면으로 이동');
            } catch (e) {
              print('0494 호출 실패: $e');
            }
          },
          child: Container(
            padding: EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.list_alt, size: 20, color: Colors.blue[600]),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[800],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '설비 목록 보기 ($code)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blue[600]),
              ],
            ),
          ),
        ),
      );
    }

    // FLAG가 'X'가 아니면 일반 ExpansionTile
    return DynamicCustomExpansionTile(
      title: title,
      tplnr: code,
      depth: childDepth,
      rootItem: widget.rootItem,
      parentItem: childItem,
      treeDataService: widget.treeDataService,
    );
  }
}