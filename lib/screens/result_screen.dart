import 'package:flutter/material.dart';
import '../core/api/api_exception.dart';
import '../models/play_models.dart';
import '../repositories/play_session_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';
import 'result_widgets.dart';

const _kMaxPoll = 5;
const _kPollDelay = Duration(seconds: 3);

class ResultScreen extends StatefulWidget {
  const ResultScreen({this.sessionId, super.key});
  final int? sessionId;
  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  bool _loading = false;
  String? _error;
  DeductionResult? _data;
  bool _exhausted = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: AppMotion.dur3);
    _fade = CurvedAnimation(parent: _ctrl, curve: AppMotion.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 10),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: AppMotion.easeOut));
    widget.sessionId != null ? _startPoll(widget.sessionId!) : _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _startPoll(int id) async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
      _exhausted = false;
    });
    await _poll(id, 0);
  }

  Future<void> _poll(int id, int attempt) async {
    if (!mounted) return;
    try {
      final r = await playSessionRepo.result(id);
      if (!mounted) return;
      setState(() {
        _data = r;
        _loading = false;
      });
      _ctrl.forward();
    } on ApiException catch (e) {
      if (!mounted) return;
      final notReady = e.isNotFound || e.status == 202;
      final isTransientError = e.isNetwork || e.status == null;

      if ((notReady || isTransientError) && attempt < _kMaxPoll - 1) {
        await Future.delayed(_kPollDelay);
        if (mounted) await _poll(id, attempt + 1);
        return;
      }
      setState(() {
        _loading = false;
        _exhausted = notReady || attempt >= _kMaxPoll - 1;
        _error = notReady ? '채점이 아직 완료되지 않았습니다. 잠시 후 다시 확인해 주세요.' : e.message;
      });
    } catch (_) {
      if (!mounted) return;
      if (attempt < _kMaxPoll - 1) {
        await Future.delayed(_kPollDelay);
        if (mounted) await _poll(id, attempt + 1);
        return;
      }
      setState(() {
        _loading = false;
        _exhausted = true;
        _error = '결과를 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.transparent,
        automaticallyImplyLeading: false,
        titleSpacing: AppTokens.sp4,
        title: Text(
          'CASE CLOSED',
          style: AppText.monoLabel.copyWith(color: c.textMute),
        ),
      ),
      body: ResultBody(
        loading: _loading,
        error: _error,
        exhausted: _exhausted,
        data: _data,
        fade: _fade,
        slide: _slide,
        onRetry: widget.sessionId != null
            ? () => _startPoll(widget.sessionId!)
            : null,
        onHome: () => Navigator.of(context).popUntil((r) => r.isFirst),
      ),
    );
  }
}
