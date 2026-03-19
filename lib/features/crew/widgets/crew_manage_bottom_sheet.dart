import 'package:flutter/material.dart';
import 'package:triagain/core/constants/app_colors.dart';
import 'package:triagain/core/constants/app_sizes.dart';
import 'package:triagain/core/constants/app_text_styles.dart';

class CrewManageBottomSheet extends StatelessWidget {
  final int currentMembers;
  final bool isLeader;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onLeave;

  const CrewManageBottomSheet({
    super.key,
    required this.currentMembers,
    this.isLeader = true,
    this.onEdit,
    this.onDelete,
    this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    final canDelete = currentMembers <= 1;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey2,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          if (isLeader) ...[
            // 크루 수정
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.white),
              title: Text(
                '크루 수정',
                style: AppTextStyles.body1.copyWith(color: AppColors.white),
              ),
              onTap: onEdit,
            ),

            // 크루 삭제
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: canDelete ? AppColors.error : AppColors.grey2,
              ),
              title: Text(
                '크루 삭제',
                style: AppTextStyles.body1.copyWith(
                  color: canDelete ? AppColors.error : AppColors.grey2,
                ),
              ),
              subtitle: canDelete
                  ? null
                  : Text(
                      '크루원이 있어 삭제할 수 없습니다',
                      style:
                          AppTextStyles.caption.copyWith(color: AppColors.grey3),
                    ),
              onTap: canDelete ? onDelete : null,
            ),
          ],

          if (!isLeader && onLeave != null)
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: Text(
                '크루 탈퇴',
                style: AppTextStyles.body1.copyWith(color: AppColors.error),
              ),
              onTap: onLeave,
            ),

          SizedBox(height: AppSizes.paddingLG + MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
