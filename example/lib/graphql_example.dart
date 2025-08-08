import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter_dev_panel/flutter_dev_panel.dart';
import 'package:flutter_dev_panel_network/flutter_dev_panel_network.dart';

/// GraphQL 集成示例
class GraphQLExample extends StatefulWidget {
  @override
  _GraphQLExampleState createState() => _GraphQLExampleState();
}

class _GraphQLExampleState extends State<GraphQLExample> {
  late GraphQLClient client;
  late ValueNotifier<GraphQLClient> clientNotifier;

  @override
  void initState() {
    super.initState();
    
    // ========== 方式1：最简单 - 直接附加到现有客户端 ==========
    // 创建你自己的GraphQL客户端
    final originalClient = GraphQLClient(
      link: HttpLink('https://countries.trevorblades.com/'),
      cache: GraphQLCache(),
    );
    
    // 一行代码添加监控（类似attachToDio）
    client = NetworkModule.attachToGraphQL(originalClient);
    
    // ========== 方式2：在Link层面集成 ==========
    /*
    final httpLink = HttpLink('https://countries.trevorblades.com/');
    final authLink = AuthLink(getToken: () => 'Bearer token');
    
    // 获取监控拦截器
    final monitoringLink = NetworkModule.createGraphQLInterceptor();
    
    // 组合Link链（监控器放最前面）
    final link = Link.from([
      monitoringLink,  // 监控
      authLink,        // 认证
      httpLink,        // HTTP
    ]);
    
    client = GraphQLClient(
      link: link,
      cache: GraphQLCache(),
    );
    */
    
    // ========== 方式3：创建全新的监控客户端 ==========
    /*
    client = NetworkModule.createGraphQLClient(
      endpoint: 'https://countries.trevorblades.com/',
      defaultHeaders: {
        'Authorization': 'Bearer token',
      },
    );
    */
    
    clientNotifier = ValueNotifier(client);
  }

  @override
  Widget build(BuildContext context) {
    return GraphQLProvider(
      client: clientNotifier,
      child: Scaffold(
        appBar: AppBar(
          title: Text('GraphQL Example'),
        ),
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '使用 NetworkModule.attachToGraphQL() 一行代码添加监控',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            Expanded(
              child: CountriesList(),
            ),
          ],
        ),
      ),
    );
  }
}

class CountriesList extends StatelessWidget {
  final String query = r'''
    query GetCountries($first: Int) {
      countries(first: $first) {
        code
        name
        emoji
        capital
        currency
        languages {
          name
        }
      }
    }
  ''';

  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(
        document: gql(query),
        variables: {'first': 20},
      ),
      builder: (QueryResult result, {fetchMore, refetch}) {
        if (result.isLoading) {
          return Center(child: CircularProgressIndicator());
        }

        if (result.hasException) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 48, color: Colors.red),
                SizedBox(height: 16),
                Text('Error: ${result.exception}'),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: refetch,
                  child: Text('Retry'),
                ),
              ],
            ),
          );
        }

        final countries = result.data?['countries'] as List? ?? [];

        return RefreshIndicator(
          onRefresh: () async {
            await refetch?.call();
          },
          child: ListView.builder(
            itemCount: countries.length,
            itemBuilder: (context, index) {
              final country = countries[index];
              final languages = country['languages'] as List? ?? [];
              
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Text(
                    country['emoji'] ?? '',
                    style: TextStyle(fontSize: 32),
                  ),
                  title: Text(
                    country['name'] ?? 'Unknown',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Code: ${country['code']}'),
                      Text('Capital: ${country['capital'] ?? 'N/A'}'),
                      Text('Currency: ${country['currency'] ?? 'N/A'}'),
                      if (languages.isNotEmpty)
                        Text('Languages: ${languages.map((l) => l['name']).join(', ')}'),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// Mutation示例
class AddCommentMutation extends StatelessWidget {
  final String mutation = r'''
    mutation AddComment($postId: ID!, $text: String!) {
      addComment(postId: $postId, text: $text) {
        id
        text
        createdAt
        author {
          name
        }
      }
    }
  ''';

  @override
  Widget build(BuildContext context) {
    return Mutation(
      options: MutationOptions(
        document: gql(mutation),
        onCompleted: (data) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Comment added successfully!')),
          );
        },
        onError: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${error?.graphqlErrors.first.message}')),
          );
        },
      ),
      builder: (runMutation, result) {
        return ElevatedButton(
          onPressed: () {
            runMutation({
              'postId': '123',
              'text': 'Great post!',
            });
          },
          child: result?.isLoading == true
              ? CircularProgressIndicator(color: Colors.white)
              : Text('Add Comment'),
        );
      },
    );
  }
}

// Subscription示例
class CommentSubscription extends StatelessWidget {
  final String subscription = r'''
    subscription OnCommentAdded($postId: ID!) {
      commentAdded(postId: $postId) {
        id
        text
        author {
          name
        }
      }
    }
  ''';

  @override
  Widget build(BuildContext context) {
    return Subscription(
      options: SubscriptionOptions(
        document: gql(subscription),
        variables: {'postId': '123'},
      ),
      builder: (result) {
        if (result.isLoading) {
          return Text('Waiting for comments...');
        }
        
        final comment = result.data?['commentAdded'];
        if (comment != null) {
          return ListTile(
            title: Text(comment['text']),
            subtitle: Text('By: ${comment['author']['name']}'),
          );
        }
        
        return Text('No new comments');
      },
    );
  }
}