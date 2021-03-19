from rest_framework.pagination import PageNumberPagination
from rest_framework.response import Response


class AnalyzePagination(PageNumberPagination):
    page_size = 20
    page_size_query_param = 'per_page'
    max_page_size = 1000
    # paginate_by_param = 'page_size'

    def get_paginated_response(self, data):
        return Response({
            'paginate': {
                'page': self.page.number,
                'count': self.page.paginator.count,
                'per_page': self.page.paginator.per_page,
                'num_pages': self.page.paginator.num_pages,
            },
            'items': data
        })

    def get_page_size(self, request):
        if self.page_size_query_param:
            page_size = min(int(request.query_params.get(
                self.page_size_query_param, self.page_size)), self.max_page_size)
            if page_size > 0:
                return page_size
            elif page_size == 0:
                return None
            else:
                pass
        return self.page_size
