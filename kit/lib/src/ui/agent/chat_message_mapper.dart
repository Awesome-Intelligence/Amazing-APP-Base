import 'dart:convert';

import 'package:kit_agent/kit_agent.dart' as agent;

import 'chat_message.dart';

/// kit_agent 的运行态消息 → kit 的展示态消息。
///
/// 两个包各有一份 ChatMessage 是有意的：kit_agent 那份是**运行态**（steps 可变、文本累积），
/// kit 那份是**不可变展示态**（widget 比较友好）。边界就放在这一层 —— app 直接用这个函数，
/// 别再各写一份（写两份就一定会分叉）。
List<ChatMessage> mapChatMessages(List<agent.ChatMessage> messages) => [
      for (final m in messages)
        switch (m) {
          agent.UserChatMessage(:final text) => ChatMessage.user(text),
          agent.AssistantChatMessage(:final text, :final steps) => ChatMessage.assistant(
              text: text,
              steps: [
                for (final s in steps)
                  ChatStep(
                    tool: s.toolName,
                    args: s.args.isEmpty ? '' : jsonEncode(s.args),
                    status: switch (s.status) {
                      agent.ChatStepStatus.pending ||
                      agent.ChatStepStatus.running =>
                        ChatStepStatus.running,
                      agent.ChatStepStatus.done => ChatStepStatus.done,
                      agent.ChatStepStatus.failed => ChatStepStatus.failed,
                    },
                    result: s.result ?? s.error,
                  ),
              ],
            ),
          agent.SystemChatMessage(:final text) => ChatMessage.system(text),
          agent.ErrorChatMessage(:final message) => ChatMessage.error(message),
        },
    ];
